//
//  CCConvertClient.m
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/5.
//

#import "CCConvertClient.h"
#import "CCChatGPTManager.h"
#import "CCVoice2TextManager.h"
#import "CCChatGPTResponse.h"

static CCConvertClient *shareClient;

@interface CCConvertClient () <CCVoice2TextManagerDelegate>

@property (nonatomic, strong) CCConvertClientConfig *config;

@end

@implementation CCConvertClient

+ (instancetype)shared
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareClient = [[CCConvertClient alloc] init];
    });
    return shareClient;
}

- (void)configClient:(CCConvertClientConfig *)config
{
    _config = config;
    [CCChatGPTManager.shared configClient:config];
    [CCVoice2TextManager.shared configClient:config];
    CCVoice2TextManager.shared.delegate = self;
}

- (AgoraRtcEngineKit *)agoraKit
{
    return CCVoice2TextManager.shared.agoraKit;
}

- (void)hyStart
{
    [CCVoice2TextManager.shared hyStart];
}

- (void)hyFlush
{
    [CCVoice2TextManager.shared hyFlush];
}

- (void)hyStop
{
    [CCVoice2TextManager.shared hyStop];
}

- (void)setSystem:(NSString *)content
{
    [CCChatGPTManager.shared appendSystemMessage:content];
}

- (void)sendQuestionToChatGPT:(NSString *)question response:(CCChatGPTResponseBlock)response
{
    [CCChatGPTManager.shared sendQuestionToChatGPT:question response:response];
}

- (void)cc_voice2TextManagerOnResult:(NSString *)result subEnd:(BOOL)subEnd
{
    if ([_delegate respondsToSelector:@selector(cc_converClientVoice2TextOnResult:subEnd:)]) {
        [_delegate cc_converClientVoice2TextOnResult:result subEnd:subEnd];
    }
    if (_autoQuestioning && subEnd) {
        __weak typeof(self) weakSelf = self;
        [self sendQuestionToChatGPT:result response:^(CCChatGPTResponse * _Nullable response, NSError * _Nullable error) {
            if ([weakSelf.delegate respondsToSelector:@selector(cc_converClientOnChatGPTAnswer:error:)]) {
                [weakSelf.delegate cc_converClientOnChatGPTAnswer:response error:error];
            }
        }];
    }
}

- (void)cc_voice2TextManagerOnEnd
{
    if ([_delegate respondsToSelector:@selector(cc_converClientVoice2TextOnEnd)]) {
        [_delegate cc_converClientVoice2TextOnEnd];
    }
}

- (void)cc_voice2TextManagerOnError:(int)error message:(NSString *)message
{
    if ([_delegate respondsToSelector:@selector(cc_converClientVoice2TextOnError:message:)]) {
        [_delegate cc_converClientVoice2TextOnError:error message:message];
    }
}

@end

@implementation CCConvertClientConfig

- (instancetype)init
{
    if (self = [super init]) {
        _limitChatMessageCount = 30;
    }
    return self;
}

@end
