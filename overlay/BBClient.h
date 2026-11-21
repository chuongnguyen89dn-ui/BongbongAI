#import <Foundation/Foundation.h>
@interface BBClient : NSObject
- (void)ask:(NSString *)question completion:(void (^)(NSString *reply, NSString *error))done;
- (void)makeSpeech:(NSString *)reply completion:(void (^)(NSData *wav, NSString *error))done;
- (void)cancel;
@end
