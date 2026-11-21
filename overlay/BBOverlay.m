#import "BBOverlay.h"
#import "BBClient.h"
#import "BBAudio.h"
#import <UIKit/UIKit.h>

@interface BBPassthroughWindow : UIWindow
@property(nonatomic,assign) CGRect bubbleHit;
@property(nonatomic,assign) CGRect panelHit;
@property(nonatomic,assign) BOOL panelVisible;
@end
@implementation BBPassthroughWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // Every touch outside bubble/panel passes through to CarPlay.
    return CGRectContainsPoint(self.bubbleHit,point) ||
           (self.panelVisible && CGRectContainsPoint(self.panelHit,point));
}
@end

@interface BBOverlay () <UITextFieldDelegate>
@property(nonatomic,strong) BBPassthroughWindow *window;
@property(nonatomic,strong) UIWindowScene *boundScene;
@property(nonatomic,strong) UIButton *bubble;
@property(nonatomic,strong) UIView *panel;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UITextView *answer;
@property(nonatomic,strong) UITextField *question;
@property(nonatomic,strong) BBClient *client;
@property(nonatomic,strong) BBAudio *audio;
@property(nonatomic,assign) BOOL expanded;
@property(nonatomic,assign) CGPoint bubbleCenter;
@property(nonatomic,assign) NSUInteger requestEpoch;
@property(nonatomic,assign) BOOL observersInstalled;
@end

@implementation BBOverlay
+ (instancetype)shared {
    static BBOverlay *instance;static dispatch_once_t once;
    dispatch_once(&once,^{instance=[BBOverlay new];});return instance;
}
- (instancetype)init {
    if ((self=[super init])) {self.client=[BBClient new];self.audio=[BBAudio new];}
    return self;
}
- (void)start {
    if (self.observersInstalled) return;
    self.observersInstalled=YES;
    NSNotificationCenter *nc=NSNotificationCenter.defaultCenter;
    for (NSNotificationName n in @[UISceneDidActivateNotification,
                                    UISceneWillDeactivateNotification,
                                    UISceneDidDisconnectNotification,
                                    UIApplicationDidBecomeActiveNotification,
                                    UIScreenDidConnectNotification,
                                    UIScreenDidDisconnectNotification]) {
        [nc addObserver:self selector:@selector(sceneChanged:) name:n object:nil];
    }
    [self refreshScene];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(2*NSEC_PER_SEC)),
                   dispatch_get_main_queue(),^{[self refreshScene];});
}
- (void)sceneChanged:(NSNotification *)note {[self refreshScene];}
- (UIWindowScene *)eligibleScene {
    UIScreen *phone=[UIScreen mainScreen];
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) continue;
        UIWindowScene *windowScene=(id)scene;
        if (!windowScene.screen || windowScene.screen==phone) continue;
        if ((windowScene.activationState!=UISceneActivationStateForegroundActive &&
             windowScene.activationState!=UISceneActivationStateForegroundInactive) ||
             windowScene.screen.bounds.size.width<200) continue;
        return windowScene;
    }
    return nil; // Fail closed; never display bubble on iPhone.
}
- (void)refreshScene {
    UIWindowScene *scene=[self eligibleScene];
    if (scene==self.boundScene && self.window) {
        [self layoutUI];return;
    }
    [self.client cancel];[self.audio stop];self.requestEpoch++;
    self.window.hidden=YES;self.window.rootViewController=nil;self.window=nil;
    self.boundScene=nil;self.panel=nil;self.bubble=nil;self.status=nil;self.answer=nil;
    self.question=nil;self.expanded=NO;
    if (!scene) {NSLog(@"[BongbongAI] BLIND no external UIWindowScene");return;}
    self.boundScene=scene;
    BBPassthroughWindow *window=[[BBPassthroughWindow alloc] initWithWindowScene:scene];
    window.frame=scene.coordinateSpace.bounds;
    window.backgroundColor=UIColor.clearColor;
    window.windowLevel=UIWindowLevelAlert+25;window.opaque=NO;
    UIViewController *root=[UIViewController new];root.view.backgroundColor=UIColor.clearColor;
    window.rootViewController=root;self.window=window;
    [self buildUIIn:root.view];[self layoutUI];
    window.hidden=NO; // Avoid makeKeyAndVisible and stealing CarPlay's focused window.
    NSLog(@"[BongbongAI] external scene attached (not device validated)");
}
- (UIButton *)button:(NSString *)title action:(SEL)sel color:(UIColor *)color {
    UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
    [b setTitle:title forState:UIControlStateNormal];
    [b setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    b.titleLabel.font=[UIFont boldSystemFontOfSize:14];
    b.backgroundColor=color;b.layer.cornerRadius=10;
    [b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return b;
}
- (void)buildUIIn:(UIView *)root {
    self.bubble=[self button:@"AI" action:@selector(toggle:) color:
        [UIColor colorWithRed:.46 green:.20 blue:.88 alpha:1]];
    self.bubble.layer.cornerRadius=28;self.bubble.layer.borderWidth=2;
    self.bubble.layer.borderColor=UIColor.whiteColor.CGColor;
    self.bubble.accessibilityLabel=@"BongbongAI";[root addSubview:self.bubble];
    UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(drag:)];
    [self.bubble addGestureRecognizer:pan];

    self.panel=[UIView new];self.panel.backgroundColor=[UIColor colorWithRed:.07 green:.06 blue:.12 alpha:.96];
    self.panel.layer.cornerRadius=18;self.panel.layer.borderWidth=1;
    self.panel.layer.borderColor=[UIColor colorWithRed:.65 green:.43 blue:1 alpha:.8].CGColor;
    self.panel.hidden=YES;[root addSubview:self.panel];

    UILabel *title=[UILabel new];
    title.text=@"BongbongAI · Gemini";title.textColor=UIColor.whiteColor;
    title.font=[UIFont boldSystemFontOfSize:18];title.tag=110;[self.panel addSubview:title];

    self.question=[UITextField new];self.question.placeholder=@"Nhập câu hỏi (xe đang đỗ)";
    self.question.backgroundColor=UIColor.whiteColor;self.question.textColor=UIColor.blackColor;
    self.question.layer.cornerRadius=8;self.question.font=[UIFont systemFontOfSize:14];
    self.question.delegate=self;self.question.returnKeyType=UIReturnKeySend;
    [self.panel addSubview:self.question];

    self.answer=[UITextView new];
    self.answer.text=@"Nhập Gemini API key của bạn trong BongbongAI Config trên iPhone; không qua Cloudflare.";
    self.answer.font=[UIFont systemFontOfSize:14];self.answer.textColor=UIColor.whiteColor;
    self.answer.editable=NO;self.answer.scrollEnabled=YES;
    self.answer.backgroundColor=UIColor.clearColor;self.answer.tag=111;
    [self.panel addSubview:self.answer];

    self.status=[UILabel new];self.status.text=@"Sẵn sàng: hỏi bằng chữ hoặc câu mẫu.";
    self.status.textColor=[UIColor colorWithRed:.74 green:.56 blue:1 alpha:1];
    self.status.font=[UIFont systemFontOfSize:12];self.status.numberOfLines=2;
    [self.panel addSubview:self.status];

    UIButton *ask=[self button:@"Hỏi AI" action:@selector(ask:) color:
        [UIColor colorWithRed:.46 green:.20 blue:.88 alpha:1]];
    ask.tag=112;[self.panel addSubview:ask];
    UIButton *diagnostic=[self button:@"Đọc thử" action:@selector(diagnostic:) color:
        [UIColor colorWithRed:.28 green:.31 blue:.42 alpha:1]];
    diagnostic.tag=113;[self.panel addSubview:diagnostic];
    UIButton *stop=[self button:@"Dừng" action:@selector(stop:) color:
        [UIColor colorWithRed:.55 green:.17 blue:.23 alpha:1]];
    stop.tag=114;[self.panel addSubview:stop];
}
- (void)layoutUI {
    if (!self.window || !self.bubble) return;
    CGSize size=self.window.bounds.size;
    if (size.width<200 || size.height<200) {self.window.hidden=YES;return;}
    self.window.hidden=NO;
    if (CGPointEqualToPoint(self.bubbleCenter,CGPointZero))
        self.bubbleCenter=CGPointMake(size.width-44,size.height-74);
    self.bubbleCenter=CGPointMake(MIN(MAX(28,self.bubbleCenter.x),size.width-28),
                                MIN(MAX(28,self.bubbleCenter.y),size.height-28));
    self.bubble.frame=CGRectMake(self.bubbleCenter.x-28,self.bubbleCenter.y-28,56,56);
    CGFloat w=MIN(440,size.width-24),h=MIN(288,size.height-20);
    self.panel.frame=CGRectMake((size.width-w)/2,(size.height-h)/2,w,h);
    self.window.bubbleHit=self.bubble.frame;
    self.window.panelHit=self.panel.frame;
    self.window.panelVisible=self.expanded;
    [[self.panel viewWithTag:110] setFrame:CGRectMake(16,12,w-30,26)];
    self.question.frame=CGRectMake(16,44,w-32,36);
    self.answer.frame=CGRectMake(16,88,w-32,MAX(48,h-182));
    self.status.frame=CGRectMake(16,h-88,w-32,28);
    CGFloat buttonWidth=(w-48)/3.;
    for (NSInteger i=0;i<3;i++) {
        [[self.panel viewWithTag:112+i] setFrame:CGRectMake(12+i*(buttonWidth+6),h-53,buttonWidth,41)];
    }
}
- (void)toggle:(id)sender {
    self.expanded=!self.expanded;self.panel.hidden=!self.expanded;
    self.window.panelVisible=self.expanded;
    if (!self.expanded) [self.question resignFirstResponder];
}
- (void)drag:(UIPanGestureRecognizer *)pan {
    if (!self.window) return;
    CGPoint diff=[pan translationInView:self.window];
    self.bubbleCenter=CGPointMake(self.bubbleCenter.x+diff.x,self.bubbleCenter.y+diff.y);
    [pan setTranslation:CGPointZero inView:self.window];[self layoutUI];
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {
    [field resignFirstResponder];[self ask:nil];return YES;
}
- (void)report:(NSString *)message {
    self.status.text=message;NSLog(@"[BongbongAI] phase=%@",message);
}
- (void)ask:(id)sender {
    NSString *question=[self.question.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (!question.length)
        question=@"Xin chào. Hãy giới thiệu ngắn về Bongbong AI bằng một câu tiếng Việt hoàn chỉnh.";
    [self.question resignFirstResponder];[self.client cancel];[self.audio stop];
    NSUInteger epoch=++self.requestEpoch;[self report:@"Đang lấy văn bản Gemini..."];
    __weak typeof(self) weakSelf=self;
    [self.client ask:question completion:^(NSString *reply,NSString *error) {
        BBOverlay *owner=weakSelf;
        if (!owner || epoch!=owner.requestEpoch) return;
        if (error) {[owner report:error];return;}
        owner.answer.text=reply;[owner report:@"Đã đủ văn bản; chờ PCM/TTS..."];
        [owner.client makeSpeech:reply completion:^(NSData *wav,NSString *audioError) {
            if (epoch!=owner.requestEpoch) return;
            if (audioError) {[owner report:audioError];return;}
            [owner report:[NSString stringWithFormat:@"WAV %lu bytes; phát nguyên file...",(unsigned long)wav.length]];
            [owner.audio playCompleteWAV:wav onFinish:^(BOOL complete,NSString *detail) {
                if (epoch!=owner.requestEpoch) return;
                [owner report:[NSString stringWithFormat:@"%@: %@",complete?@"PLAYER XONG":@"CHƯA ĐẠT",detail]];
            }];
        }];
    }];
}
- (void)diagnostic:(id)sender {
    [self.client cancel];[self.audio stop];
    NSUInteger epoch=++self.requestEpoch;
    [self report:@"Đọc thử Apple TTS trên route hiện tại..."];
    __weak typeof(self) weakSelf=self;
    [self.audio playDiagnosticSentence:^(BOOL complete,NSString *detail) {
        BBOverlay *owner=weakSelf;
        if (!owner || epoch!=owner.requestEpoch) return;
        [owner report:detail];
    }];
}
- (void)stop:(id)sender {
    self.requestEpoch++;[self.client cancel];[self.audio stop];
    [self report:@"Đã dừng theo yêu cầu."];
}
@end
