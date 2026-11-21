#import <Foundation/Foundation.h>
@interface BBAudio : NSObject
- (BOOL)playCompleteWAV:(NSData *)wav onFinish:(void (^)(BOOL completed,NSString *detail))done;
- (void)playDiagnosticSentence:(void (^)(BOOL completed, NSString *detail))done;
- (void)stop;
@end
