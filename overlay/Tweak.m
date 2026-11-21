#import <Foundation/Foundation.h>
#import "BBOverlay.h"

// No injection or hooks into any other third-party tweak or app.
__attribute__((constructor)) static void BBInstall(void) {
    @autoreleasepool {
        if (![NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.CarPlayApp"]) return;
        dispatch_async(dispatch_get_main_queue(), ^{ [[BBOverlay shared] start]; });
    }
}
