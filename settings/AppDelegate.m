#import "AppDelegate.h"
#import <CoreFoundation/CoreFoundation.h>

@interface AppDelegate ()
@property(nonatomic,strong) UITextField *keyInput;
@property(nonatomic,strong) UILabel *status;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *vc=[UIViewController new];
    vc.view.backgroundColor=[UIColor colorWithRed:.08 green:.07 blue:.12 alpha:1];
    UILabel *title=[UILabel new];
    title.text=@"BongbongAI · Gemini trực tiếp (v0.1.1)";title.numberOfLines=0;
    title.textColor=UIColor.whiteColor;title.font=[UIFont boldSystemFontOfSize:20];
    UILabel *info=[UILabel new];
    info.text=@"Nhập Gemini API key của riêng bạn. Không cần Cloudflare. Ứng dụng iPhone chỉ cấu hình; bong bóng chỉ hiện trên màn CarPlay.";
    info.textColor=UIColor.lightGrayColor;info.numberOfLines=0;info.font=[UIFont systemFontOfSize:15];
    self.keyInput=[UITextField new];self.keyInput.placeholder=@"Nhập Gemini API key";
    self.keyInput.secureTextEntry=YES;self.keyInput.backgroundColor=UIColor.whiteColor;
    self.keyInput.textColor=UIColor.blackColor;self.keyInput.layer.cornerRadius=10;
    self.keyInput.autocapitalizationType=UITextAutocapitalizationTypeNone;
    self.keyInput.autocorrectionType=UITextAutocorrectionTypeNo;
    self.keyInput.spellCheckingType=UITextSpellCheckingTypeNo;
    self.keyInput.smartDashesType=UITextSmartDashesTypeNo;
    self.keyInput.keyboardType=UIKeyboardTypeASCIICapable;
    self.keyInput.delegate=self;self.keyInput.clearButtonMode=UITextFieldViewModeWhileEditing;
    [self.keyInput addTarget:self action:@selector(keyChanged:) forControlEvents:UIControlEventEditingChanged];
    // iOS 16+ native paste control: no direct UIPasteboard read.
    UIPasteControlConfiguration *pasteConfig=[[UIPasteControlConfiguration alloc] init];
    pasteConfig.baseBackgroundColor=[UIColor colorWithRed:.34 green:.20 blue:.55 alpha:1];
    pasteConfig.baseForegroundColor=UIColor.whiteColor;
    UIPasteControl *pasteKey=[[UIPasteControl alloc] initWithConfiguration:pasteConfig];
    pasteKey.target=self.keyInput;
    pasteKey.accessibilityLabel=@"Dán API key từ bộ nhớ tạm";
    // Fallback for systems where UIPasteControl is disabled or does not transfer text.
    // Read only as a direct consequence of the user's button tap. iOS may prompt to Allow Paste.
    UIButton *pasteFallback=[self button:@"Dán API key (cách 2)" action:@selector(pasteFromClipboard:)];
    UIButton *save=[self button:@"Lưu API key" action:@selector(save:)];
    UIButton *erase=[self button:@"Xóa API key" action:@selector(erase:)];
    self.status=[UILabel new];self.status.numberOfLines=0;
    self.status.textColor=[UIColor colorWithRed:.75 green:.58 blue:1 alpha:1];
    self.status.font=[UIFont systemFontOfSize:14];
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[title,info,self.keyInput,pasteKey,pasteFallback,save,erase,self.status]];
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=18;
    stack.translatesAutoresizingMaskIntoConstraints=NO;[vc.view addSubview:stack];
    UILayoutGuide *safe=vc.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:25],
        [self.keyInput.heightAnchor constraintEqualToConstant:46],
        [pasteKey.heightAnchor constraintEqualToConstant:44],
        [pasteFallback.heightAnchor constraintEqualToConstant:44],
        [save.heightAnchor constraintEqualToConstant:44],
        [erase.heightAnchor constraintEqualToConstant:44]]];
    self.window.rootViewController=vc;[self.window makeKeyAndVisible];
    self.status.text=@"v0.1.1: sao chép key trên iPhone; dùng Dán hoặc Dán API key (cách 2), rồi Lưu. Chỉ dùng key thử nghiệm: preferences chưa mã hóa như Keychain.";
    return YES;
}
- (UIButton *)button:(NSString *)text action:(SEL)sel {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:text forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.backgroundColor=[UIColor colorWithRed:.48 green:.25 blue:.78 alpha:1];
    b.layer.cornerRadius=10;[b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)keyChanged:(UITextField *)field {
    // Confirm entry without logging or displaying the secret itself.
    self.status.text=field.text.length
        ? @"Đã nhận nội dung vào ô key. Nhấn Lưu API key để áp dụng."
        : @"Chưa có API key. Sao chép key, chạm Dán (Paste), rồi Lưu.";
}
- (void)pasteFromClipboard:(id)sender {
    // This is exclusively invoked by a visible user-tap button. On iOS 16+ the OS
    // may display an "Allow Paste" privacy prompt; never read clipboard on launch.
    NSString *copied=[UIPasteboard generalPasteboard].string;
    if (![copied isKindOfClass:NSString.class] || !copied.length) {
        self.status.text=@"Không lấy được chữ từ clipboard. Hãy sao chép API key trên iPhone, bấm Cho phép Dán nếu iOS hỏi, rồi thử lại.";
        return;
    }
    NSString *normalized=[copied stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    self.keyInput.text=normalized;
    // Report only character count, never clipboard/key content or any prefix.
    self.status.text=[NSString stringWithFormat:@"Đã dán %lu ký tự. Bấm Lưu API key.",(unsigned long)normalized.length];
}
- (void)save:(id)sender {
    NSString *v=[self.keyInput.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (v.length<16 || v.length>512 ||
        [v rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location!=NSNotFound) {
        self.status.text=@"Key không hợp lệ, chưa lưu.";return;
    }
    CFPreferencesSetAppValue(CFSTR("geminiAPIKey"),(__bridge CFStringRef)v,CFSTR("com.chuong.bongbongai"));
    Boolean synced=CFPreferencesAppSynchronize(CFSTR("com.chuong.bongbongai"));
    id saved=CFBridgingRelease(CFPreferencesCopyAppValue(CFSTR("geminiAPIKey"),CFSTR("com.chuong.bongbongai")));
    BOOL verified=synced && [saved isKindOfClass:NSString.class] && [saved isEqualToString:v];
    if (verified) self.keyInput.text=@"";
    self.status.text=verified
        ? @"v0.1.1: Đã lưu và đọc lại key trong ứng dụng iPhone. Còn cần xác minh CarPlay đọc được."
        : @"Lỗi lưu hoặc đọc lại key trên iPhone. Chưa coi là lưu thành công.";
}
- (void)erase:(id)sender {
    CFPreferencesSetAppValue(CFSTR("geminiAPIKey"),NULL,CFSTR("com.chuong.bongbongai"));
    Boolean ok=CFPreferencesAppSynchronize(CFSTR("com.chuong.bongbongai"));
    self.keyInput.text=@"";
    self.status.text=ok?@"Đã xóa key khỏi preferences.":@"Không xóa được key.";
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {
    [field resignFirstResponder];return YES;
}
@end
