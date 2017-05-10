//
//  RtcController.m
//  Intermobile
//  可视对讲控制类实现
//  Created by 安卓工控 on 2017/2/17.
//  Copyright © 2017年 Facebook. All rights reserved.
//
#import <SystemConfiguration/CaptiveNetwork.h>
#import "ReactBridge.h"
#import "RtcController.h"
#import <SMS_SDK/SMSSDK.h>

//RCTConvert类支持的的类型也都可以使用,RCTConvert还提供了一系列辅助函数，用来接收一个JSON值并转换到原生Objective-C类型或类。
#import "RCTConvert.h"
//本地模块也可以给JavaScript发送事件通知。最直接的方式是使用eventDispatcher
#import "RCTEventDispatcher.h"

static ReactBridge *_INSTANCE=nil;

@implementation ReactBridge
{
  int liftStatus;
}
//----------与react native通信桥梁----

@synthesize bridge = _bridge;

- (ReactBridge *)init
{
  liftStatus=0;
  self = [super init];
  if (self) {
    _INSTANCE=self;
  }
  [self startWifiChecking];
  return self;
}

RCT_EXPORT_MODULE(ReactBridge);

RCT_EXPORT_METHOD(sendMainMessage:(int)code parameter:(NSString *)parameter)
{
  RCTLogInfo(@"ReactBridge ------>try to send Main Service<------- %d and %@", code, parameter);
  if(code==10000) //设置URL地址
  {
    [RtcController setApplicationUrl:parameter];
  }
  else if(code==10001) //设置用户账户，并且开始登录RTC
  {
    RtcController *rtcController=[RtcController getInstance];
    [rtcController login:parameter];
  }
  else if(code==10002) //退出登录
  {
    RtcController *rtcController=[RtcController getInstance];
    [rtcController unRegister];
  }
  else if(code==40001) //检测RTC状态
  {
    int rtcCode=0;
    RtcController *rtcController=[RtcController getInstance];
    if([rtcController accObjIsRegisted])
    {
      rtcCode=10;
    }
    [self sendMessageToReact:@"changeRtcStatus" notification:@{@"rtcStatus":[NSNumber numberWithInt:(rtcCode)]}];
    [self sendMessageToReact:@"changeLiftStatus" notification:@{@"liftStatus":[NSNumber numberWithInt:(liftStatus)]}];
  }
  else if(code==20033) //直接打开门襟设备
  {
    RtcController *rtcController=[RtcController getInstance];
    [rtcController openLock:parameter];
  }
  else if(code==50001) //直接打开室内机设备
  {
    RtcController *rtcController=[RtcController getInstance];
    [rtcController openTalk:parameter];
  }
}

- (void)sendMessageToReact:(NSString*)eventName notification:(NSNotification *)notification
{
  [self.bridge.eventDispatcher sendAppEventWithName:eventName body:notification];
}
//------------短信验证方法------------

RCT_EXPORT_METHOD(sendSms:(NSString *)phone)
{
  RCTLogInfo(@"ReactBridge ------>try to send SMS to<------- %@", phone);
  [SMSSDK getVerificationCodeByMethod:SMSGetCodeMethodSMS phoneNumber:phone
                                 zone:@"86"
                     customIdentifier:nil
                               result:^(NSError *error){
                                 if (!error) {
                                   [self sendMessageToReact:@"sendSmsSuccess" notification:nil];
                                 } else {
                                   [self sendMessageToReact:@"sendSmsFail" notification:nil];
                                 }
                               }];
}

RCT_EXPORT_METHOD(verifySms:(NSString *)phone code:(NSString*)code)
{
  RCTLogInfo(@"ReactBridge ------>try to verify SMS for<------- %@", phone);
  [SMSSDK commitVerificationCode:code phoneNumber:phone zone:@"86" result:^(SMSSDKUserInfo *userInfo, NSError *error) {
      if(!error)
      {
        RCTLogInfo(@"ReactBridge ------>verify sms success<------- %@", phone);
        [self sendMessageToReact:@"verifySmsSuccess" notification:nil];
      }
      else
      {
        RCTLogInfo(@"ReactBridge ------>verify sms failed<------- %@", phone);
        [self sendMessageToReact:@"verifySmsFail" notification:nil];
      }
  }];
}

+(ReactBridge *)getInstance
{
  return _INSTANCE;
}

+(void)sendMessage:(NSString*)eventName notification:(NSNotification *)notification
{
  ReactBridge *reactBridge=[ReactBridge getInstance];
  [reactBridge sendMessageToReact:eventName notification:notification];
}

//-------------检测当前WIFI信息--------------
-(void)startWifiChecking
{
  [NSTimer scheduledTimerWithTimeInterval:1
                                   target:self
                                 selector:@selector(wifiChecking:)
                                 userInfo:nil
                                  repeats:YES];
}

-(void)wifiChecking:(NSTimer *)timer
{
  BOOL checkResult=NO;
  NSString *wifiName=[ReactBridge getWifiName];
  if(wifiName){
    if([LIFT_WIFI_SSID isEqualToString:wifiName]){
      checkResult=YES;
    }
  }
  if(checkResult)
  {
    if(liftStatus!=10)
    {
      liftStatus=10;
      [self sendMessageToReact:@"changeLiftStatus" notification:@{@"liftStatus":[NSNumber numberWithInt:(liftStatus)]}];
    }
  }
  else
  {
    if(liftStatus!=0)
    {
      liftStatus=0;
      [self sendMessageToReact:@"changeLiftStatus" notification:@{@"liftStatus":[NSNumber numberWithInt:(liftStatus)]}];
    }
  }
}

//获得当前连接的WI-FI信号SSID
+ (NSString *)getWifiName
{
  NSString *wifiName = nil;
  
  CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
  
  if (!wifiInterfaces) {
    return nil;
  }
  
  NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
  
  for (NSString *interfaceName in interfaces) {
    CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
    
    if (dictRef) {
      NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
      wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
      
      CFRelease(dictRef);
    }
  }
  
  CFRelease(wifiInterfaces);
  return wifiName;
}

@end
