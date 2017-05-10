#import "CallController.h"

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <AVFoundation/AVCaptureSession.h>
#import <CoreMotion/CoreMotion.h>
#import "RtcController.h"

@interface CallController ()
{
  BOOL speakerState;//NO 听筒;YES 扬声
  NSTimer* callDurationTimer;
  CGRect screenRect;
  int marginHeight;
  int marginWidth;
  int imageSize;
  int labelHeight;
  int buttonSize;
  int toolBarY;
}
@property (nonatomic,strong) IBOutlet UILabel* lockNameLabel;
@property (nonatomic,strong) IBOutlet UIImageView* callingImageView;
@property (nonatomic,strong) UIButton* rejectButton;
@property (nonatomic,strong) UIButton* openLockButton;
@property (nonatomic,strong) UIButton* voiceButton;
@property (nonatomic,strong) UIButton* videoButton;
@property (nonatomic,strong) UIButton* speakerSwitchButton;
@property (nonatomic,strong) UIButton* closeRtcButton;
@property (nonatomic,strong) UIButton* closeRtcAndOpenLockButton;
@end

@implementation CallController
@synthesize remoteVideoView = _remoteVideoView;
@synthesize rejectButton,openLockButton,voiceButton,videoButton,speakerSwitchButton,closeRtcButton,closeRtcAndOpenLockButton;
@synthesize callingImageView;


#pragma mark - Func
//--------------------界面部分---------------
- (void)loadView
{
  UIView *view=[[UIView alloc]initWithFrame:[[UIScreen mainScreen]applicationFrame]];
  self.view=view;
  view.backgroundColor=[UIColor blackColor];
  [self initScreen];
}

//界面初始化
-(void)initScreen
{
  screenRect=self.view.bounds;
  marginHeight=screenRect.size.height/10;
  marginWidth=screenRect.size.width/10;
  imageSize=screenRect.size.width*4/5;
  labelHeight=30;
  buttonSize=80;
  toolBarY=screenRect.size.height-marginHeight-buttonSize;
  [self initLockLabel];
  [self initImageUrl];
  [self initVideoView];
  [self initToolbar];
  [self initRtcToolbar];
  [self setRtcToolbarHidden:YES];
}

//初始化门襟名称label
-(void)initLockLabel
{
  CGRect labelFrame=CGRectMake(0, (marginHeight*2+imageSize), screenRect.size.width,labelHeight);
  self.lockNameLabel=[[UILabel alloc]initWithFrame:labelFrame];
  self.lockNameLabel.textAlignment =NSTextAlignmentCenter;
  [self.lockNameLabel setTextColor:[UIColor whiteColor]];
  self.lockNameLabel.text=@"";
  [self.view addSubview:self.lockNameLabel];
}

//初始化呼叫图片
-(void)initImageUrl
{
  self.callingImageView=[[UIImageView alloc] initWithFrame:CGRectMake(marginWidth,marginHeight,imageSize, imageSize)];
  self.callingImageView.layer.masksToBounds = YES;
  [self.view addSubview:self.callingImageView];
}

//设置图片
-(void)setCallingImage:(NSString *)imageUrlValue
{
  if(imageUrlValue!=nil)
  {
    NSString *urlValue=[[NSString alloc] initWithFormat:@"%@%@",[RtcController getApplicationUrl],imageUrlValue];
    NSURL *imageUrl = [NSURL URLWithString:urlValue];
    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageUrl]];
    self.callingImageView.image = image;
  }
  else
  {
    NSString *filePath=[[NSBundle mainBundle] pathForResource:@"guest" ofType:@"png"];
    UIImage *image=[UIImage imageWithContentsOfFile:filePath];
    self.callingImageView.image = image;
  }
}

//初始化可视对讲图像View
-(void)initVideoView
{
  int videoWidth=130;
  int videoHeight=170;
  int videoViewWidth=0;
  int videoViewHeight=0;
  if(screenRect.size.width/(toolBarY-marginHeight)>videoWidth/videoHeight)
  {
    videoViewHeight=(toolBarY-marginHeight);
    videoViewWidth=(toolBarY-marginHeight)*videoWidth/videoHeight;
  }
  else
  {
    videoViewWidth=imageSize;
    videoViewHeight=imageSize*videoHeight/videoWidth;
  }
  self.remoteVideoView = [[IOSDisplay alloc]initWithFrame:CGRectMake((screenRect.size.width-videoViewWidth)/2,((toolBarY-marginHeight-videoViewHeight)/2+marginHeight),videoViewWidth, videoViewHeight)];
  [self.view addSubview:self.remoteVideoView];
}

//初始化工具条
-(void)initToolbar
{
  int buttonNumber=4;
  int buttonMargin=(screenRect.size.width-buttonNumber*buttonSize)/(buttonNumber+1);
  CGRect rejectButtonFrame=CGRectMake((buttonMargin*1+buttonSize*0), toolBarY, buttonSize, buttonSize);
  [self.rejectButton=[UIButton alloc]initWithFrame:rejectButtonFrame];
  [self.rejectButton setTitle:@"关闭" forState:UIControlStateNormal];
  [self.rejectButton setBackgroundColor:[UIColor blackColor]];
  [self.rejectButton addTarget:self action:@selector(onReject:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.rejectButton];
  
  CGRect openLockButtonFrame=CGRectMake((buttonMargin*2+buttonSize*1), toolBarY, buttonSize, buttonSize);
  [self.openLockButton=[UIButton alloc]initWithFrame:openLockButtonFrame];
  [self.openLockButton setTitle:@"开门" forState:UIControlStateNormal];
  [self.openLockButton setBackgroundColor:[UIColor blackColor]];
  [self.openLockButton addTarget:self action:@selector(onOpenDoor:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.openLockButton];
  
  CGRect voiceButtonFrame=CGRectMake((buttonMargin*3+buttonSize*2), toolBarY, buttonSize, buttonSize);
  [self.voiceButton=[UIButton alloc]initWithFrame:voiceButtonFrame];
  [self.voiceButton setTitle:@"音频" forState:UIControlStateNormal];
  [self.voiceButton setBackgroundColor:[UIColor blackColor]];
  [self.voiceButton addTarget:self action:@selector(onAcceptVoice:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.voiceButton];
  
  CGRect videoButtonFrame=CGRectMake((buttonMargin*4+buttonSize*3), toolBarY, buttonSize, buttonSize);
  [self.videoButton=[UIButton alloc]initWithFrame:videoButtonFrame];
  [self.videoButton setTitle:@"视频" forState:UIControlStateNormal];
  [self.videoButton setBackgroundColor:[UIColor blackColor]];
  [self.videoButton addTarget:self action:@selector(onAcceptVideo:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.videoButton];
}

-(void)setToolbarHidden:(BOOL)isHidden
{
  [rejectButton setHidden:isHidden];
  [openLockButton setHidden:isHidden];
  [voiceButton setHidden:isHidden];
  [videoButton setHidden:isHidden];
}

-(void)setRtcToolbarHidden:(BOOL)isHidden
{
  [speakerSwitchButton setHidden:isHidden];
  [closeRtcButton setHidden:isHidden];
  [closeRtcAndOpenLockButton setHidden:isHidden];
}

-(void)setCallInfoHidden:(BOOL)isHidden
{
  [self.lockNameLabel setHidden:isHidden];
  [self.callingImageView setHidden:isHidden];
}

//初始化工具条
-(void)initRtcToolbar
{
  int buttonNumber=3;
  int buttonMargin=(screenRect.size.width-buttonNumber*buttonSize)/(buttonNumber+1);
  CGRect speakerSwitchButtonFrame=CGRectMake((buttonMargin*1+buttonSize*0), toolBarY, buttonSize, buttonSize);
  [self.speakerSwitchButton=[UIButton alloc]initWithFrame:speakerSwitchButtonFrame];
  [self.speakerSwitchButton setTitle:@"切换免提" forState:UIControlStateNormal];
  [self.speakerSwitchButton setBackgroundColor:[UIColor blackColor]];
  [self.speakerSwitchButton addTarget:self action:@selector(onSwitchSpeaker:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.speakerSwitchButton];
  
  CGRect closeRtcButtonFrame=CGRectMake((buttonMargin*2+buttonSize*1), toolBarY, buttonSize, buttonSize);
  [self.closeRtcButton=[UIButton alloc]initWithFrame:closeRtcButtonFrame];
  [self.closeRtcButton setTitle:@"挂断" forState:UIControlStateNormal];
  [self.closeRtcButton setBackgroundColor:[UIColor blackColor]];
  [self.closeRtcButton addTarget:self action:@selector(onHangUp:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.closeRtcButton];
  
  CGRect closeRtcAndOpenLockButtonFrame=CGRectMake((buttonMargin*3+buttonSize*2), toolBarY, buttonSize, buttonSize);
  [self.closeRtcAndOpenLockButton=[UIButton alloc]initWithFrame:closeRtcAndOpenLockButtonFrame];
  [self.closeRtcAndOpenLockButton setTitle:@"开门" forState:UIControlStateNormal];
  [self.closeRtcAndOpenLockButton setBackgroundColor:[UIColor blackColor]];
  [self.closeRtcAndOpenLockButton addTarget:self action:@selector(onHangupAndOpenDoor:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:self.closeRtcAndOpenLockButton];
}

- (void)viewDidDisappear:(BOOL)animated
{
  
}

-(void)viewDidAppear:(BOOL)animated
{
    callDurationTimer = [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(onTimeoutChecking:) userInfo:nil repeats:NO];
}

-(void)onCalling:(NSString*)lockName imageUrl:(NSString*)imageUrl
{
  [self setCallingImage:imageUrl];
  self.lockNameLabel.text=lockName;
  
}

-(void)appendCallImage:(NSString*)imageUrl
{
  [self setCallingImage:imageUrl];
}
//--------------定时检查------------

-(void)onTimeoutChecking:(NSTimer*)timer
{
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"params",
                          [NSNumber numberWithInt:MSG_CALL_TIMEOUT],@"msgid",
                          [NSNumber numberWithInt:0],@"arg",
                          nil];
  [[NSNotificationCenter defaultCenter]  postNotificationName:@"RTC_NOTIFY_EVENT" object:nil userInfo:params];
}

//关闭超时检查
-(void)clearTimeoutChecking
{
  if(callDurationTimer)
  {
    if (callDurationTimer.isValid)
    {
      [callDurationTimer invalidate];
      callDurationTimer=nil;
    }
  }
}

//--------------响应事件------------

//发送事件消息
-(void)sendRtcNotifyEvent:(eventid)eventId
{
  NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:@"", @"params",
                          [NSNumber numberWithInt:eventId],@"msgid",
                          nil,@"arg",
                          nil];
  [[NSNotificationCenter defaultCenter]  postNotificationName:@"RTC_NOTIFY_EVENT" object:nil userInfo:params];
}

//挂断
-(IBAction)onHangUp:(id)sender
{
  [self sendRtcNotifyEvent:MSG_HANGUP];
}

//挂断并且开门
-(IBAction)onHangupAndOpenDoor:(id)sender
{
  [self sendRtcNotifyEvent:MSG_HANGUP_AND_OPEN];
}

//拒接
-(IBAction)onReject:(id)sender
{
  [self clearTimeoutChecking];
  [self sendRtcNotifyEvent:MSG_REJECT];
}

//直接开门
-(IBAction)onOpenDoor:(id)sender
{
  [self clearTimeoutChecking];
  [self sendRtcNotifyEvent:MSG_OPEN_DOOR];
}

//接听视频
-(IBAction)onAcceptVideo:(id)sender
{
  [self setLog:@"已接听"];
  [self clearTimeoutChecking];
  [self setCallInfoHidden:YES];
  [self setToolbarHidden:YES];
  [self setRtcToolbarHidden:NO];
  [self sendRtcNotifyEvent:MSG_ACCEPT_VIDEO];
}

//接听音频
-(IBAction)onAcceptVoice:(id)sender
{
  [self setLog:@"已接听"];
  [self clearTimeoutChecking];
  [self setToolbarHidden:YES];
  [self setRtcToolbarHidden:NO];
  [self sendRtcNotifyEvent:MSG_ACCEPT_VOICE];
}

//转换听筒模式
-(IBAction)onSwitchSpeaker:(id)sender
{
  [self sendRtcNotifyEvent:MSG_SET_AUDIO_DEVICE];
}

-(void)setLog:(NSString*)log
{
    NSDateFormatter *dateFormat=[[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"HH:mm:ss"];
    NSString* datestr = [dateFormat stringFromDate:[NSDate date]];
    CWLogDebug(@"SDKTEST:%@:%@",datestr,log);
}

@end
