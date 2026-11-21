#import "AppDelegate.h"
#import <CoreFoundation/CoreFoundation.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface AppDelegate () <UIDocumentPickerDelegate>
@property(nonatomic,strong) UITextField *keyInput;
@property(nonatomic,strong) UILabel *status;
@end
@implementation AppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)options {
    self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    UIViewController *vc=[UIViewController new];
    vc.view.backgroundColor=[UIColor colorWithRed:.08 green:.07 blue:.12 alpha:1];
    UILabel *title=[UILabel new];
    title.text=@"BongbongAI · Gemini trực tiếp (v0.1.2)";title.numberOfLines=0;
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
    UIButton *importFile=[self button:@"Nhập API key từ Tệp .txt" action:@selector(importTextFile:)];
    UIButton *inspect=[self button:@"Kiểm tra số ký tự đã nhập" action:@selector(inspectKey:)];
    UIButton *save=[self button:@"Lưu API key" action:@selector(save:)];
    UIButton *erase=[self button:@"Xóa API key" action:@selector(erase:)];
    self.status=[UILabel new];self.status.numberOfLines=0;
    self.status.textColor=[UIColor colorWithRed:.75 green:.58 blue:1 alpha:1];
    self.status.font=[UIFont systemFontOfSize:14];
    UIStackView *stack=[[UIStackView alloc] initWithArrangedSubviews:@[title,info,self.keyInput,pasteKey,pasteFallback,importFile,inspect,save,erase,self.status]];
    stack.axis=UILayoutConstraintAxisVertical;stack.spacing=18;
    UIScrollView *scroll=[UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints=NO;
    scroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;
    [vc.view addSubview:scroll];
    stack.translatesAutoresizingMaskIntoConstraints=NO;
    [scroll addSubview:stack];
    UILayoutGuide *safe=vc.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor constant:-20],
        [stack.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor constant:25],
        [stack.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor constant:-20],
        [stack.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor constant:-40],
        [self.keyInput.heightAnchor constraintEqualToConstant:46],
        [pasteKey.heightAnchor constraintEqualToConstant:44],
        [pasteFallback.heightAnchor constraintEqualToConstant:44],
        [importFile.heightAnchor constraintEqualToConstant:44],
        [inspect.heightAnchor constraintEqualToConstant:44],
        [save.heightAnchor constraintEqualToConstant:44],
        [erase.heightAnchor constraintEqualToConstant:44]]];
    self.window.rootViewController=vc;[self.window makeKeyAndVisible];
    self.status.text=@"v0.1.2: nếu cả hai nút Dán không hoạt động, dùng Nhập API key từ Tệp .txt. Kiểm tra số ký tự rồi Lưu. Chỉ dùng key thử nghiệm vì preferences chưa phải Keychain.";
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
- (void)inspectKey:(id)sender {
    NSUInteger n=self.keyInput.text.length;
    self.status.text=n
        ? [NSString stringWithFormat:@"Ô nhập đang có %lu ký tự (nội dung được che). Nhấn Lưu API key.",(unsigned long)n]
        : @"Ô nhập rỗng: chưa có ký tự nào, dù nút Dán có xuất hiện.";
}
- (void)importTextFile:(id)sender {
    // System document picker. Works without UIPasteboard and can import a key
    // securely transferred to the same iPhone using Files/AirDrop.
    UIDocumentPickerViewController *picker=[[UIDocumentPickerViewController alloc]
       initForOpeningContentTypes:@[UTTypePlainText] asCopy:YES];
    picker.allowsMultipleSelection=NO;
    picker.delegate=self;
    [self.window.rootViewController presentViewController:picker animated:YES completion:nil];
}
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url=urls.firstObject;
    if (!url.isFileURL) {self.status.text=@"Không chọn được tệp chữ hợp lệ.";return;}
    BOOL scoped=[url startAccessingSecurityScopedResource];
    NSError *error=nil;
    NSNumber *size=nil;
    NSDictionary *attrs=[[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:&error];
    if ([attrs[NSFileSize] isKindOfClass:NSNumber.class]) size=attrs[NSFileSize];
    NSData *bytes=nil;
    if (!error && size && size.unsignedLongLongValue>0 && size.unsignedLongLongValue<=4096) {
        bytes=[NSData dataWithContentsOfURL:url options:0 error:&error];
    }
    if (scoped) [url stopAccessingSecurityScopedResource];
    // The picker was created with asCopy:YES. Clean only an imported copy inside
    // this app's sandbox, never delete a document outside our own container.
    NSString *ownPrefix=[NSHomeDirectory() stringByAppendingString:@"/"];
    if ([[url.path stringByStandardizingPath] hasPrefix:ownPrefix]) {
        [[NSFileManager defaultManager] removeItemAtURL:url error:NULL];
    }
    if (!bytes.length || bytes.length>4096) {
        self.status.text=@"Không đọc được tệp .txt hoặc tệp vượt 4 KB. Key chưa nhập.";
        return;
    }
    NSString *raw=[[NSString alloc] initWithData:bytes encoding:NSUTF8StringEncoding];
    NSString *key=[raw stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!key || key.length<16 || key.length>512 ||
        [key rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location!=NSNotFound) {
        self.status.text=@"Tệp không chứa đúng một API key (16–512 ký tự, không có dấu cách). Chưa nhập.";
        return;
    }
    self.keyInput.text=key;
    self.status.text=[NSString stringWithFormat:@"Đã nhập %lu ký tự từ tệp. Bấm Lưu API key.",(unsigned long)key.length];
}
- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {
    self.status.text=@"Đã hủy chọn tệp. API key chưa thay đổi.";
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
        ? @"v0.1.2: Đã lưu và đọc lại key trên iPhone. Vẫn cần kiểm tra CarPlay đọc được."
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
