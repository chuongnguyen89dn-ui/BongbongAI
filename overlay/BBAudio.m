#import "BBAudio.h"
#import <AVFoundation/AVFoundation.h>

@interface BBAudio () <AVAudioPlayerDelegate,AVSpeechSynthesizerDelegate>
@property(nonatomic,strong) AVAudioPlayer *player;
@property(nonatomic,strong) AVSpeechSynthesizer *diagnostic;
@property(nonatomic,copy) void (^finish)(BOOL,NSString *);
@property(nonatomic,assign) NSTimeInterval started;
@property(nonatomic,assign) NSTimeInterval duration;
@end
@implementation BBAudio
- (void)stop {
    self.finish=nil;
    [self.player stop];self.player=nil;
    [self.diagnostic stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];self.diagnostic=nil;
}
- (BOOL)playCompleteWAV:(NSData *)wav onFinish:(void (^)(BOOL,NSString *))done {
    [self stop];
    NSError *err=nil;
    self.player=[[AVAudioPlayer alloc] initWithData:wav error:&err];
    if (!self.player || ![self.player prepareToPlay]) {
        self.player=nil;if (done) done(NO,@"Không giải mã được WAV đầy đủ.");return NO;
    }
    self.player.delegate=self;
    self.duration=self.player.duration;
    if (self.duration<=0 || self.duration>180) {
        self.player=nil;if (done) done(NO,@"WAV có duration không hợp lệ.");return NO;
    }
    self.finish=done;
    self.started=NSProcessInfo.processInfo.systemUptime;
    if (![self.player play]) {
        self.player=nil;self.finish=nil;
        if (done) done(NO,@"AVAudioPlayer không thể bắt đầu phát.");return NO;
    }
    return YES; // One buffered full file. Never schedule fragmented Live chunks.
}
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (player!=self.player) return;
    NSTimeInterval elapsed=NSProcessInfo.processInfo.systemUptime-self.started;
    BOOL complete=flag && elapsed>=MAX(0,self.duration-.35);
    void (^done)(BOOL,NSString *)=self.finish;
    self.finish=nil;self.player=nil;
    if (done) done(complete,[NSString stringWithFormat:@"WAV %.1fs, callback %.1fs (chưa chứng minh loa)",self.duration,elapsed]);
}
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    if (player!=self.player) return;
    void (^done)(BOOL,NSString *)=self.finish;
    self.finish=nil;self.player=nil;
    if (done) done(NO,[NSString stringWithFormat:@"Lỗi audio %ld",(long)error.code]);
}
- (void)playDiagnosticSentence:(void (^)(BOOL,NSString *))done {
    [self stop];self.finish=done;
    self.diagnostic=[AVSpeechSynthesizer new];self.diagnostic.delegate=self;
    AVSpeechUtterance *u=[AVSpeechUtterance speechUtteranceWithString:
        @"Đây là phép thử giọng nói độc lập của Bongbong AI. Câu phải đọc đến từ cuối cùng."];
    u.voice=[AVSpeechSynthesisVoice voiceWithLanguage:@"vi-VN"];
    u.rate=.46;[self.diagnostic speakUtterance:u];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)s didFinishSpeechUtterance:(AVSpeechUtterance *)u {
    if (s!=self.diagnostic) return;
    void (^done)(BOOL,NSString *)=self.finish;
    self.finish=nil;self.diagnostic=nil;
    if (done) done(YES,@"TTS didFinish, cần xác minh nghe đầy đủ trên xe.");
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)s didCancelSpeechUtterance:(AVSpeechUtterance *)u {
    if (s!=self.diagnostic) return;
    void (^done)(BOOL,NSString *)=self.finish;
    self.finish=nil;self.diagnostic=nil;
    if (done) done(NO,@"Đọc thử bị hủy.");
}
@end
