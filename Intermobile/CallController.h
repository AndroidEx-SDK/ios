
#import <UIKit/UIKit.h>
#import "RtcController.h"

#define degreeTOradians(x) (M_PI * (x)/180)
#define CALLINGVIEW_TAG 2000

@interface CallController : UIViewController
@property (nonatomic,strong) IOSDisplay *remoteVideoView;
-(void)onCalling:(NSString*)lockName imageUrl:(NSString*)imageUrl;
-(void)appendCallImage:(NSString*)imageUrl;
@end
