//
//  CCVoice2TextManager.m
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import "CCVoice2TextManager.h"

static NSString *VendorName = @"Hy";
static NSString *ExtensionName = @"IstIts";

@interface CCVoice2TextManager () <AgoraMediaFilterEventDelegate, AgoraRtcEngineDelegate>
{
    NSMutableDictionary *istDataDict;
    
    //存放展示内容的sn
    NSMutableArray * mSnArray;
}

@property (nonatomic, strong) AgoraRtcEngineKit *agoraKit;
@property (nonatomic, strong) CCConvertClientConfig *config;
@property (nonatomic, assign) BOOL isInit;

@end

@implementation CCVoice2TextManager

+ (instancetype)shared
{
    static CCVoice2TextManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CCVoice2TextManager alloc] init];
    });
    return manager;
}

- (void)configClient:(CCConvertClientConfig *)config
{
    if (_isInit) {
        NSLog(@"can not reset config");
        return;
    }
    _config = config;
    AgoraRtcEngineConfig *cfg = [AgoraRtcEngineConfig new];
    cfg.appId = config.appId;
    cfg.eventDelegate = self;
    _agoraKit = [AgoraRtcEngineKit sharedEngineWithConfig:cfg delegate:self];
    [_agoraKit enableExtensionWithVendor:VendorName extension:ExtensionName enabled:YES];

    [_agoraKit setChannelProfile:AgoraChannelProfileLiveBroadcasting];
    [_agoraKit setClientRole:AgoraClientRoleBroadcaster];
    int v = [_agoraKit enableLocalAudio:YES];
    if (_config.debug) {
        NSLog(@"enable local audio %d", v);
    }
    
    _isInit = YES;
}

- (void)hyStart
{
    if (!_config || !_config.hyAppId || !_config.hyApiKey || !_config.hyApiSecret) {
        NSLog(@"voice2text need setup config");
        return;
    }
    
    [self.agoraKit setEnableSpeakerphone:YES];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    [istDataDict removeAllObjects];

    NSMutableDictionary *rootDict = [NSMutableDictionary dictionary];
    NSDictionary *commonDict = @{
        @"app_id": _config.hyAppId,
        @"api_key": _config.hyApiKey,
        @"api_secret": _config.hyApiSecret
    };
    [rootDict setObject:commonDict forKey:@"common"];
    NSMutableDictionary *istDict =  [NSMutableDictionary dictionary];
    [istDict setObject:@"wss://ist-api.xfyun.cn/v2/ist" forKey:@"uri"];
    
    NSDictionary *istBusinessDict = @{
        @"language":@"zh_cn",
        @"accent":@"mandarin",
        @"domain":@"ist_ed_open",
        @"language_type":@1,
        @"dwa":@"wpgs"
    };
    NSDictionary *istReqDict = @{@"business":istBusinessDict};
    [istDict setObject:istReqDict forKey:@"req"];
    [rootDict setObject:istDict forKey:@"ist"];

    NSData *data = [NSJSONSerialization dataWithJSONObject:rootDict options:NSJSONWritingPrettyPrinted error:nil];
    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    int v = [self.agoraKit setExtensionPropertyWithVendor:@"Hy" extension:@"IstIts" key:@"start_listening" value:str];
    if (_config.debug) {
        NSLog(@"hyStart  %d", v);
    }
}

- (void)hyFlush
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    int v = [self.agoraKit setExtensionPropertyWithVendor:@"Hy" extension:@"IstIts" key:@"flush_listening" value:@"{}"];
    if (_config.debug) {
        NSLog(@"hyFlush  %d", v);
    }
}

- (void)hyStop
{
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    int v = [self.agoraKit setExtensionPropertyWithVendor:@"Hy" extension:@"IstIts" key:@"stop_listening" value:@"{}"];
    if (_config.debug) {
        NSLog(@"hyStop  %d", v);
    }
}

- (void)parseIst:(NSString *)key result:(NSDictionary*)dict
{
   NSMutableString *str = [NSMutableString string];
   int code = [[dict objectForKey:@"code"] intValue];
   if (0 != code) {
       return;
   }
   NSDictionary *dataDict = [dict objectForKey:@"data"];
   if (dataDict.count) {
       int status = [dict[@"status"] intValue];
       NSDictionary *resultDict = dataDict[@"result"];
       if (resultDict.count) {
           NSNumber *sn = resultDict[@"sn"];
           bool sub_end = [resultDict[@"sub_end"] boolValue];
           NSArray *rgArray = resultDict[@"rg"];
           NSArray *wsArray = resultDict[@"ws"];
           if (wsArray !=nil) {
               NSInteger count = wsArray.count;
               for (int i = 0; i < count; i++) {
                   NSDictionary *wsItemDict = wsArray[i];
                   if (wsItemDict.count) {
                       NSArray *cwArray = wsItemDict[@"cw"];
                       if (cwArray != nil) {
                           NSDictionary *cwItemDict = cwArray[0];
                           NSString *w = cwItemDict[@"w"];
                           if (![self isBlankString:w]) {
                               if (str.length > 0 || ![cwItemDict[@"wp"] isEqualToString:@"p"]) {
                                   [str appendFormat:@"%@", w];
                               }
                           }
                       }
                   }
               }
           }
           if (rgArray != nil) {
               int start = [rgArray[0] intValue];
               int end = [rgArray[1] intValue];
               for (int i = start; i <= end; i++) {
                   istDataDict[[NSNumber numberWithInt:i]] = @"";
               }
           }
           istDataDict[sn] = str;
           
           NSMutableString *strShow = [NSMutableString string];
           int count = (int)mSnArray.count;
           int loopTimes = 3;
           //最多显示最后4次的结果
           if (count < 3) {
               loopTimes = count;
           }
           
           for (int i = loopTimes; i > 0; i--) {
               NSNumber *sn = mSnArray[count - i];
               NSString *data = istDataDict[sn];
               if (![self isBlankString:data]) {
                   [strShow appendFormat:@"%@",data];
               }
           }
           
           [strShow appendFormat:@"%@",str];
           
           if ((2 == status || sub_end) && ![self isBlankString:str]) {
               [mSnArray addObject:sn];
           }
           dispatch_async(dispatch_get_main_queue(), ^{
               if ([self.delegate respondsToSelector:@selector(cc_voice2TextManagerOnResult:subEnd:)]) {
                   [self.delegate cc_voice2TextManagerOnResult:strShow subEnd:sub_end];
               }
           });
       }
   }
}

- (BOOL)isBlankString:(NSString *)string
{
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

- (void)onEvent:(NSString *)provider extension:(NSString *)extension key:(NSString *)key value:(NSString *)value
{
    if ([provider isEqualToString:VendorName] && [extension isEqualToString:ExtensionName]) {
        if (_config.debug) {
            NSLog(@"onEvent(provider: %@, extension: %@, key: %@, value: %@)", provider, extension, key, value);
        }
        if ([key isEqualToString:@"error"]) {
            if ([_delegate respondsToSelector:@selector(cc_voice2TextManagerOnError:message:)]) {
                [_delegate cc_voice2TextManagerOnError:-1 message:value];
            }
            return;
        } else if ([key isEqualToString:@"end"]) {
            if ([self.delegate respondsToSelector:@selector(cc_voice2TextManagerOnEnd)]) {
                [self.delegate cc_voice2TextManagerOnEnd];
            }
        } else if ([key isEqualToString:@"ist_result"]) {
            NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
            NSError *error;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                if ([_delegate respondsToSelector:@selector(cc_voice2TextManagerOnError:message:)]) {
                    [_delegate cc_voice2TextManagerOnError:-1 message:@"json parse error"];
                }
            }
            [self parseIst:key result:dict];
        }
    }
}

- (void)onExtensionError:(NSString *)provider extension:(NSString *)extension error:(int)error message:(NSString *)message
{
    if ([provider isEqualToString:VendorName] && [extension isEqualToString:ExtensionName]) {
        if (_config.debug) {
            NSLog(@"onEvent(provider: %@, extension: %@, error: %d, message: %@)", provider, extension, error, message);
        }
        if ([_delegate respondsToSelector:@selector(cc_voice2TextManagerOnError:message:)]) {
            [_delegate cc_voice2TextManagerOnError:error message:message];
        }
    }
}

@end
