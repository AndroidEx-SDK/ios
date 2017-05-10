//
//  UDPHandler.m
//  Intermobile
//
//  Created by 结点科技 on 2017/3/4.
//  Copyright © 2017年 Facebook. All rights reserved.
//

#import "UDPHandler.h"
#import "GCDAsyncUdpSocket.h"

@interface UDPHandler()
{
  long tag;
  
  RCTResponseSenderBlock callback;
}

@end

@implementation UDPHandler

// 因为实例是全局的 因此要定义为全局变量，且需要存储在静态区，不释放。不能存储在栈区。
static UDPHandler *handler = nil;
GCDAsyncUdpSocket *udpSocket;
static NSString *address = @"192.168.0.199";
static uint16_t  port = 9000;
// 是否响应
bool responed = YES;


// 伪单例 和 完整的单例。 以及线程的安全。
// 一般使用伪单例就足够了 每次都用 sharedDataHandle 创建对象。
+ (UDPHandler *) shareInstance
{
  // 添加同步锁，一次只能一个线程访问。如果有多个线程访问，等待。一个访问结束后下一个。
  @synchronized(self){
    if (nil == handler) {
      handler = [[UDPHandler alloc] init];
    }
  }
  return handler;
}

- (uint8_t) setupSocket
{
  if(udpSocket != nil) {
    return 0;
  };
  // 初始化udp
  udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
  
  NSError *error = nil;
  // 连接socket服务端
//  if(![udpSocket connectToHost:address onPort:port error:&error]){
//    NSLog(@"连接失败：%@",error);
//    [self response:nil err:@"设备连接失败"];
//    return 1;
//  }
  
  if(![udpSocket bindToPort:0 error:&error]){
    NSLog(@"连接失败：%@",error);
    [self response:nil err:@"设备连接失败"];
    return 2;
  }
  
  // 开始接收数据
  if(![udpSocket beginReceiving:&error]){
    NSLog(@"beginReceiving：%@",error);
    [self response:nil err:@"数据接收异常"];
    return 3;
  }
  
  return 0;
  
}

/**
 *  写数据
 */
- (void) write:(NSString *) msg cb:(RCTResponseSenderBlock)cb
{
  /*if(responed == NO) {
    cb(@[@"等待设备响应中"]);
    return;
  }*/
  
  self->callback = cb;
  uint8_t code = [self setupSocket];
  if(code != 0){
    return;
  }
  NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
  
  responed = NO;
  [udpSocket sendData:data toHost:address port:port withTimeout:1500 tag:tag];
  tag++;
}


/**
 *  接收服务器返回数据
 */
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
  NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
  if (msg)
  {
    NSLog(@"RECV: %@", msg);
  }
  else
  {
    NSString *host = nil;
    uint16_t port = 0;
    [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
    NSLog(@"RECV: Unknown message from: %@:%hu", host, port);
  }
  
  [self response:msg err:nil];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
  [self response:nil err:[error localizedDescription]];
}


/**
 *  响应回调函数
 */
- (void) response:(NSString *) data err:(NSString *) error{
  
  responed = YES;
  
  if(callback != nil){
    if (error == nil){
      callback(@[[NSNull null],data]);
    }else{
      callback(@[error,[NSNull null]]);
    }
    callback = nil;
  }
  
}

@end
