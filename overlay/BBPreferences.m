#import "BBPreferences.h"
#import <CoreFoundation/CoreFoundation.h>

// Prototype only. Cross-process sharing and secret protection NOT yet device-verified.
NSString *BBGeminiKey(void) {
    CFPropertyListRef value=CFPreferencesCopyAppValue(CFSTR("geminiAPIKey"),CFSTR("com.chuong.bongbongai"));
    id obj=CFBridgingRelease(value);
    return [obj isKindOfClass:NSString.class] ? obj : @"";
}
