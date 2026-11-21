#import "BBClient.h"
#import "BBPreferences.h"
#import "BBPCMCore.h"
#include <string.h>

static NSString * const BBAPI = @"https://generativelanguage.googleapis.com/v1beta/interactions";
static NSString * const BBTextModel = @"gemini-3.5-flash-lite";
// 3.1 TTS Preview was shut down 2026-11-17; use the stable 3.8 family.
static NSString * const BBTTSModel = @"gemini-3.8-flash-tts";

static NSDictionary *BBDict(id obj) {return [obj isKindOfClass:NSDictionary.class] ? obj : nil;}
static NSArray *BBArray(id obj) {return [obj isKindOfClass:NSArray.class] ? obj : nil;}
static NSString *BBString(id obj) {return [obj isKindOfClass:NSString.class] ? obj : nil;}

static NSString *BBCleanText(NSString *text) {
    return [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

/* Segment only for TTS requests; every character remains in order. No text is dropped. */
static NSArray<NSString *> *BBSpeechSegments(NSString *text, NSUInteger limit) {
    NSMutableArray<NSString *> *parts=[NSMutableArray array];
    NSString *remaining=BBCleanText(text);
    while (remaining.length) {
        if (parts.count>=16) return nil; // bounded cost and audio-memory pressure
        if (remaining.length<=limit) { [parts addObject:remaining]; break; }
        NSRange composed=[remaining rangeOfComposedCharacterSequenceAtIndex:limit-1];
        NSUInteger end=NSMaxRange(composed);
        NSString *prefix=[remaining substringToIndex:end];
        NSUInteger cut=0;
        for (NSUInteger i=end;i>limit/2;i--) {
            unichar c=[prefix characterAtIndex:i-1];
            if (c=='.' || c=='!' || c=='?' || c=='\n' || c==';' || c==0x3002) {
                cut=i;break;
            }
        }
        if (!cut) {
            for (NSUInteger i=end;i>limit/2;i--) {
                unichar c=[prefix characterAtIndex:i-1];
                if ([[NSCharacterSet whitespaceCharacterSet] characterIsMember:c]) {cut=i;break;}
            }
        }
        if (!cut) cut=end;
        NSString *segment=BBCleanText([remaining substringToIndex:cut]);
        if (!segment.length) return nil;
        [parts addObject:segment];
        remaining=BBCleanText([remaining substringFromIndex:cut]);
    }
    return parts;
}

static NSData *BBWrapPCM(NSData *pcm) {
    NSMutableData *wav=[NSMutableData dataWithLength:pcm.length+44];
    size_t written=0;
    if (!bb_pcm_to_wav(pcm.bytes,pcm.length,wav.mutableBytes,wav.length,&written)) return nil;
    wav.length=written;
    return wav;
}

@interface BBClient ()
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) NSURLSessionDataTask *task;
@property(nonatomic,assign) NSUInteger generation;
@end
@implementation BBClient
- (instancetype)init {
    if ((self=[super init])) {
        NSURLSessionConfiguration *config=[NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest=60;
        config.timeoutIntervalForResource=120;
        config.URLCache=nil;
        self.session=[NSURLSession sessionWithConfiguration:config];
    }
    return self;
}
- (void)cancel {
    self.generation++;
    [self.task cancel];self.task=nil;
}
- (void)call:(NSDictionary *)body done:(void (^)(NSDictionary *json,NSString *problem))done {
    NSString *key=BBGeminiKey();
    if (key.length<16 || key.length>512 ||
        [key rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location!=NSNotFound) {
        done(nil,@"Chưa đọc được Gemini API key. Kiểm tra Config và quyền chia sẻ giữa hai tiến trình.");
        return;
    }
    NSData *payload=[NSJSONSerialization dataWithJSONObject:body options:0 error:NULL];
    if (!payload) {done(nil,@"Không thể tạo JSON.");return;}
    [self cancel];NSUInteger fence=self.generation;
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:BBAPI]];
    request.HTTPMethod=@"POST";request.HTTPBody=payload;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"2026-05-20" forHTTPHeaderField:@"Api-Revision"];
    [request setValue:key forHTTPHeaderField:@"x-goog-api-key"];
    __weak typeof(self) weakSelf=self;
    self.task=[self.session dataTaskWithRequest:request completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            BBClient *owner=weakSelf;
            if (!owner || fence!=owner.generation) return;
            owner.task=nil;
            NSHTTPURLResponse *http=[response isKindOfClass:NSHTTPURLResponse.class]?(id)response:nil;
            if (error) {done(nil,@"Gemini mất kết nối hoặc timeout. Không phát mảnh.");return;}
            if (!http || http.statusCode!=200) {
                done(nil,[NSString stringWithFormat:@"Gemini HTTP %ld; chưa có âm thanh hoàn chỉnh.",(long)http.statusCode]);return;
            }
            if (!data.length || data.length>20*1024*1024) {done(nil,@"Phản hồi rỗng hoặc vượt trần an toàn.");return;}
            NSDictionary *json=BBDict([NSJSONSerialization JSONObjectWithData:data options:0 error:NULL]);
            if (![BBString(json[@"status"]) isEqualToString:@"completed"]) {
                done(nil,@"Gemini chưa hoàn tất. Không được phát.");return;
            }
            done(json,nil);
        });
    }];
    [self.task resume];
}
- (void)ask:(NSString *)question completion:(void (^)(NSString *reply,NSString *error))done {
    NSString *q=BBCleanText(question);
    if (!q.length || q.length>1200) {done(nil,@"Câu hỏi phải có từ 1 đến 1200 ký tự.");return;}
    NSString *prompt=[NSString stringWithFormat:
        @"Trả lời câu hỏi dưới đây bằng tiếng Việt tự nhiên, mạch lạc, đủ ý; câu hoàn chỉnh, tối đa khoảng 1200 ký tự. Không dùng Markdown hoặc nội dung không nói được. Câu hỏi: %@",q];
    [self call:@{@"model":BBTextModel,@"store":@NO,@"input":prompt} done:^(NSDictionary *json,NSString *problem) {
        if (problem) {done(nil,problem);return;}
        NSString *explicitText=BBString(json[@"output_text"]);
        if (explicitText.length) {
            NSString *complete=BBCleanText(explicitText);
            if (complete.length>4200) {done(nil,@"Câu trả lời vượt 4200 ký tự; không tự cắt lời.");return;}
            done(complete,nil);return;
        }
        NSMutableString *reply=[NSMutableString string];
        for (id entry in BBArray(json[@"steps"])) {
            NSDictionary *step=BBDict(entry);
            if (![BBString(step[@"type"]) isEqualToString:@"model_output"]) continue;
            for (id partObj in BBArray(step[@"content"])) {
                NSDictionary *part=BBDict(partObj);
                if ([BBString(part[@"type"]) isEqualToString:@"text"] && BBString(part[@"text"]))
                    [reply appendString:part[@"text"]];
            }
        }
        NSString *complete=BBCleanText(reply);
        if (!complete.length) {done(nil,@"Gemini hoàn thành nhưng không trả văn bản.");return;}
        if (complete.length>4200) {done(nil,@"Câu trả lời vượt 4200 ký tự, cần chủ động yêu cầu ngắn hơn; không cắt lời.");return;}
        done(complete,nil);
    }];
}
- (void)speechAt:(NSUInteger)idx
           parts:(NSArray<NSString *> *)parts
             pcm:(NSMutableData *)pcm
            done:(void (^)(NSData *wav,NSString *problem))done {
    if (idx>=parts.count) {
        NSData *wav=BBWrapPCM(pcm);
        if (!wav) {done(nil,@"Không tạo được WAV hoàn chỉnh.");return;}
        done(wav,nil);return;
    }
    NSString *part=parts[idx];
    NSDictionary *body=@{@"model":BBTTSModel,@"store":@NO,
        @"input":@[@{@"type":@"user_input",@"content":@[@{@"type":@"text",@"text":part}]}],
        @"response_format":@{@"type":@"audio",@"mime_type":@"audio/l16",@"sample_rate":@24000},
        @"generation_config":@{@"speech_config":@[@{@"voice":@"Kore"}]}};
    __weak typeof(self) weakSelf=self;
    [self call:body done:^(NSDictionary *json,NSString *problem) {
        BBClient *owner=weakSelf;
        if (!owner) return;
        if (problem) {done(nil,problem);return;}
        NSDictionary *audio=BBDict(json[@"output_audio"]);
        NSString *b64=BBString(audio[@"data"]);
        NSString *mime=[BBString(audio[@"mime_type"]) lowercaseString];
        if (!b64.length || (mime.length && ![mime hasPrefix:@"audio/l16"] &&
                            ![mime hasPrefix:@"audio/pcm"])) {
            done(nil,@"TTS thiếu output_audio hoặc không đúng PCM 16-bit.");return;
        }
        NSData *audioBlock=[[NSData alloc] initWithBase64EncodedString:b64 options:0];
        NSUInteger audioCount=audioBlock.length?1:0;
        if (audioCount!=1 || audioBlock.length<2400 || (audioBlock.length&1) ||
            (audioBlock.length>=4 && memcmp(audioBlock.bytes,"RIFF",4)==0)) {
            done(nil,@"TTS không trả PCM trần 24 kHz hoàn chỉnh; chặn nhầm WAV.");return;
        }
        double seconds=(double)audioBlock.length/48000.;
        if (seconds<MAX(.6,part.length/55.) || seconds>75 || pcm.length+audioBlock.length>16*1024*1024) {
            done(nil,@"TTS có thời lượng hoặc kích thước bất thường. Chặn âm thanh thiếu.");return;
        }
        [pcm appendData:audioBlock];
        // Every segment must finish; the player receives only one assembled WAV.
        [owner speechAt:idx+1 parts:parts pcm:pcm done:done];
    }];
}
- (void)makeSpeech:(NSString *)reply completion:(void (^)(NSData *wav,NSString *error))done {
    NSString *complete=BBCleanText(reply);
    if (!complete.length || complete.length>4200) {done(nil,@"TTS nhận văn bản trống hoặc vượt trần; không cắt chữ.");return;}
    NSArray<NSString *> *parts=BBSpeechSegments(complete,300);
    if (!parts.count) {done(nil,@"Không chia được văn bản mà vẫn giữ trọn nội dung.");return;}
    [self speechAt:0 parts:parts pcm:[NSMutableData data] done:done];
}
@end
