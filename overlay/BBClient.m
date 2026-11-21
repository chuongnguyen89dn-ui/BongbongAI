#import "BBClient.h"
#import "BBPreferences.h"
#import <CoreFoundation/CoreFoundation.h>

static NSString * const BBAPI=@"https://generativelanguage.googleapis.com/v1beta/interactions";
static NSString * const BBTextModel=@"gemini-3.5-flash-lite";
static NSString * const BBVoiceModel=@"gemini-3.1-flash-tts-preview";

static NSDictionary *BBDict(id v) { return [v isKindOfClass:NSDictionary.class]?v:nil; }
static NSArray *BBArray(id v) { return [v isKindOfClass:NSArray.class]?v:nil; }
static NSString *BBString(id v) { return [v isKindOfClass:NSString.class]?v:nil; }
static void BBPut16(NSMutableData *dst, uint16_t n) {
    uint16_t le=CFSwapInt16HostToLittle(n);[dst appendBytes:&le length:2];
}
static void BBPut32(NSMutableData *dst,uint32_t n) {
    uint32_t le=CFSwapInt32HostToLittle(n);[dst appendBytes:&le length:4];
}
static NSData *BBWrapPCM(NSData *pcm) {
    // Verified format required separately: mono, 16-bit, little-endian, 24000 Hz.
    if (pcm.length<24000 || pcm.length>8*1024*1024 || (pcm.length%2)!=0) return nil;
    NSMutableData *wav=[NSMutableData dataWithCapacity:pcm.length+44];
    [wav appendBytes:"RIFF" length:4];BBPut32(wav,(uint32_t)(pcm.length+36));
    [wav appendBytes:"WAVEfmt " length:8];BBPut32(wav,16);BBPut16(wav,1);
    BBPut16(wav,1);BBPut32(wav,24000);BBPut32(wav,48000);
    BBPut16(wav,2);BBPut16(wav,16);
    [wav appendBytes:"data" length:4];BBPut32(wav,(uint32_t)pcm.length);
    [wav appendData:pcm];return wav;
}
@interface BBClient ()
@property(nonatomic,strong) NSURLSession *session;
@property(nonatomic,strong) NSURLSessionDataTask *task;
@property(nonatomic,assign) NSUInteger generation;
@end
@implementation BBClient
- (instancetype)init {
    if ((self=[super init])) {
        NSURLSessionConfiguration *cfg=NSURLSessionConfiguration.ephemeralSessionConfiguration;
        cfg.timeoutIntervalForRequest=40;cfg.timeoutIntervalForResource=85;cfg.URLCache=nil;
        self.session=[NSURLSession sessionWithConfiguration:cfg];
    }
    return self;
}
- (void)cancel { self.generation++;[self.task cancel];self.task=nil; }
- (void)callWithBody:(NSDictionary *)body completed:(void (^)(NSDictionary *,NSString *))done {
    NSString *key=BBGeminiKey();
    if (key.length<16 || [key rangeOfCharacterFromSet:NSCharacterSet.whitespaceAndNewlineCharacterSet].location!=NSNotFound) {
        done(nil,@"Nhập Gemini API key trong BongbongAI Config trên iPhone.");return;
    }
    NSData *json=[NSJSONSerialization dataWithJSONObject:body options:0 error:nil];
    if (!json) {done(nil,@"Không thể tạo JSON.");return;}
    [self cancel];NSUInteger gen=self.generation;
    NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:BBAPI]];
    req.HTTPMethod=@"POST";req.HTTPBody=json;
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [req setValue:key forHTTPHeaderField:@"x-goog-api-key"];
    __weak typeof(self) weakSelf=self;
    self.task=[self.session dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *response,NSError *error) {
        dispatch_async(dispatch_get_main_queue(),^{
            BBClient *selfRef=weakSelf;
            if (!selfRef || gen!=selfRef.generation) return;
            selfRef.task=nil;
            NSHTTPURLResponse *http=[response isKindOfClass:NSHTTPURLResponse.class]?(id)response:nil;
            if (error) {done(nil,@"Gemini mất kết nối hoặc quá hạn.");return;}
            if (!http || http.statusCode!=200) {
                done(nil,[NSString stringWithFormat:@"Gemini HTTP %ld, không phát mảnh.",(long)http.statusCode]);return;
            }
            if (!data.length || data.length>12*1024*1024) {done(nil,@"Phản hồi rỗng hoặc quá lớn.");return;}
            NSDictionary *obj=BBDict([NSJSONSerialization JSONObjectWithData:data options:0 error:nil]);
            if (![BBString(obj[@"status"]) isEqualToString:@"completed"] || !BBArray(obj[@"steps"])) {
                done(nil,@"Lượt Gemini chưa hoàn tất hoặc thiếu steps.");return;
            }
            done(obj,nil);
        });
    }];
    [self.task resume];
}
- (void)ask:(NSString *)question completion:(void (^)(NSString *,NSString *))done {
    NSString *q=[question stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (q.length==0 || q.length>1200) {done(nil,@"Câu hỏi phải dài 1-1200 ký tự.");return;}
    NSString *input=[NSString stringWithFormat:@"Trả lời bằng tiếng Việt tự nhiên và trọn ý trong 1-3 câu, không quá 420 ký tự. Không dùng Markdown. Câu hỏi: %@",q];
    [self callWithBody:@{@"model":BBTextModel,@"store":@NO,@"input":input} completed:^(NSDictionary *json,NSString *error) {
        if (error) {done(nil,error);return;}
        NSMutableString *answer=[NSMutableString string];
        for (id item in BBArray(json[@"steps"])) {
            NSDictionary *step=BBDict(item);
            if (![BBString(step[@"type"]) isEqualToString:@"model_output"]) continue;
            for (id partObject in BBArray(step[@"content"])) {
                NSDictionary *part=BBDict(partObject);
                if ([BBString(part[@"type"]) isEqualToString:@"text"] && BBString(part[@"text"]))
                    [answer appendString:part[@"text"]];
            }
        }
        NSString *trimmed=[answer stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (trimmed.length==0) {done(nil,@"Gemini hoàn tất nhưng thiếu văn bản.");return;}
        if (trimmed.length>500) {done(nil,@"Văn bản quá 500 ký tự, KHÔNG cắt mất đuôi.");return;}
        done(trimmed,nil);
    }];
}
- (void)makeSpeech:(NSString *)reply completion:(void (^)(NSData *,NSString *))done {
    if (reply.length==0 || reply.length>500) {done(nil,@"TTS từ chối câu trống hoặc quá dài.");return;}
    NSString *input=[NSString stringWithFormat:@"Read aloud exactly the following Vietnamese text without omitting or adding words: %@",reply];
    NSDictionary *body=@{@"model":BBVoiceModel,@"store":@NO,@"input":input,
        @"response_format":@{@"type":@"audio"},
        @"generation_config":@{@"speech_config":@[@{@"voice":@"Kore"}]}};
    [self callWithBody:body completed:^(NSDictionary *json,NSString *error) {
        if (error) {done(nil,error);return;}
        NSMutableData *pcm=[NSMutableData data];NSUInteger blocks=0;
        for (id item in BBArray(json[@"steps"])) {
            NSDictionary *step=BBDict(item);
            if (![BBString(step[@"type"]) isEqualToString:@"model_output"]) continue;
            for (id partObject in BBArray(step[@"content"])) {
                NSDictionary *part=BBDict(partObject);
                if (![BBString(part[@"type"]) isEqualToString:@"audio"]) continue;
                NSString *data64=BBString(part[@"data"]);
                NSString *mime=[BBString(part[@"mime_type"]) lowercaseString];
                if (!data64.length || (mime.length && ![mime hasPrefix:@"audio/pcm"])) {
                    done(nil,@"TTS thiếu audio hoặc trả format không hỗ trợ.");return;
                }
                if ([mime containsString:@"rate="] && ![mime containsString:@"rate=24000"]) {
                    done(nil,@"TTS sample rate khác 24000 Hz.");return;
                }
                NSData *chunk=[[NSData alloc] initWithBase64EncodedString:data64 options:0];
                if (!chunk.length || (chunk.length%2)!=0 || pcm.length+chunk.length>8*1024*1024) {
                    done(nil,@"PCM hỏng hoặc quá lớn.");return;
                }
                [pcm appendData:chunk];blocks++;
            }
        }
        if (blocks!=1) {done(nil,@"TTS không trả đúng một audio block; không tự phát mảnh.");return;}
        double seconds=(double)pcm.length/48000.;
        if (seconds<MAX(.75,reply.length/32.) || seconds>180.) {
            done(nil,@"TTS có thời lượng bất thường.");return;
        }
        NSData *wav=BBWrapPCM(pcm);
        if (!wav) {done(nil,@"Không đóng gói được WAV.");return;}
        done(wav,nil);
    }];
}
@end
