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
    title.text=@"BongbongAI · Gemini trực tiếp";
    title.textColor=UIColor.whiteColor;title.font=[UIFont boldSystemFontOfSize:20];
    UILabel *info=[UILabel new];
    info.text=@"Nhập Gemini API key của riêng bạn. Không cần Cloudflare. Ứng dụng iPhone chỉ cấu hình; bong bóng chỉ hiện trên màn CarPlay.";
    info.textColor=UIColor.lightGrayColor;info.numberOfLines=0;info.font=[UIFont systemFontOfSize:15];
    self.keyInput=[UITextField new];self.keyInput.placeholder=@"Nhập Gemini API key";
    self.keyInput.secureTextEntry=YES;self.keyInput.backgroundColor=UIColor.whiteColor;
    self.keyInput.textColor=UIColor.blackColor;self.keyInput.layer.cornerRadius=10;
    self.keyInput.autocapitalizationType=UITextAutocapitalizationTypeNone;
    self.keyInput.autocorrectionType=UITextAutocorrectionTypeNo;
    self.keyInput.delegate=self;self.keyInput.clearButtonMode=UITextFieldViewModeWhileEditing;
    UIButton *save=[self button:@"Lưu API key" action:@selector(save:)];
    UIButton *erase=[self button:@"Xóa API key" action:@selector(erase:)];
    self.status=[UILabel new];self.status.numberOfLines=0;
    self.status.textColor=[UIColor colorWithRed:.75 green:.58 blue:1 alpha:1];
    self.status.font=[UIFont systemFontOfSize:14];
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[title,info,self.keyInput,save,erase,self.status]];
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=18;
    stack.translatesAutoresizingMaskIntoConstraints=NO;[vc.view addSubview:stack];
    UILayoutGuide *safe=vc.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [stack.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:safe.topAnchor constant:25],
        [self.keyInput.heightAnchor constraintEqualToConstant:46],
        [save.heightAnchor constraintEqualToConstant:44],
        [erase.heightAnchor constraintEqualToConstant:44]]];
    self.window.rootViewController=vc;[self.window makeKeyAndVisible];
    self.status.text=@"Prototype: key lưu ở preferences; chưa phải Keychain an toàn, chưa xác minh chéo tiến trình. Chỉ dùng key thử nghiệm có quota thấp.";
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
- (void)save:(id)sender {
    NSString *v=[self.keyInput.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (v.length<16 || v.length>512 ||
        [v rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location!=NSNotFound) {
        self.status.text=@"Key không hợp lệ, chưa lưu.";return;
    }
    CFPreferencesSetAppValue(CFSTR("geminiAPIKey"),(__bridge CFStringRef)v,CFSTR("com.chuong.bongbongai"));
    Boolean ok=CFPreferencesAppSynchronize(CFSTR("com.chuong.bongbongai"));
    self.keyInput.text=@"";
    self.status.text=ok?@"Đã lưu thử. Phải xác minh CarPlay process đọc được trước khi dùng.":@"Không lưu được preferences.";
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
