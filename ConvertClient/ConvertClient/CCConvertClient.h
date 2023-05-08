//
//  CCConvertClient.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/5.
//

#import <Foundation/Foundation.h>
#import <ConvertClient/CCChatGPTResponse.h>

@class CCConvertClientConfig;

NS_ASSUME_NONNULL_BEGIN

typedef void(^CCChatGPTResponseBlock)(CCChatGPTResponse * _Nullable response, NSError * _Nullable error);

@protocol CCConvertClientDelegate <NSObject>
@optional

/// 语音转文字成功
/// - Parameters:
///   - result: 语音转文字的结果
///   - subEnd: 是否结束了一个子句
- (void)cc_converClientVoice2TextOnResult:(NSString *)result subEnd:(BOOL)subEnd;

/// 语音转文字结束
- (void)cc_converClientVoice2TextOnEnd;

/// 语音转文字发生异常
/// - Parameters:
///   - error: 异常错误码
///   - message: 异常详细信息
- (void)cc_converClientVoice2TextOnError:(int)error message:(NSString *)message;

/// ChatGPT对问题的响应结果
/// - Parameters:
///   - response: 响应信息
///   - error: 异常信息
- (void)cc_converClientOnChatGPTAnswer:(nullable CCChatGPTResponse *)response error:(nullable NSError *)error;

@end

@interface CCConvertClient : NSObject

/// CCConvertClient的单例对象
@property (class, readonly) CCConvertClient *shared;
/// CCConvertClient事件的代理对象
@property (nonatomic, weak) id<CCConvertClientDelegate> delegate;

/// 配置CCConvertClient SDK
/// - Parameter config: 具体的配置信息
- (void)configClient:(CCConvertClientConfig *)config;

- (int)joinChannelByToken:(NSString * _Nullable)token
                channelId:(NSString * _Nonnull)channelId
                     info:(NSString * _Nullable)info
                      uid:(NSUInteger)uid
              joinSuccess:(void(^ _Nullable)(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed))joinSuccessBlock;

/// 开启语音转文字
- (void)hyStart;
/// 结束语音转文字
- (void)hyFlush;
/// 停止语音转文字
- (void)hyStop;

/// 设置请求chatgpt的系统system预设，注意会清除掉以前的记忆
/// - Parameter content: 内容
- (void)appendSystemMessage:(NSString *)content;

/// 问chatgpt问题
/// - Parameters:
///   - question: 要问chat-gpt的问题
///   - response: 问题响应的回调
- (void)sendQuestionToChatGPT:(NSString *)question response:(CCChatGPTResponseBlock)response;

@end

@interface CCConvertClientConfig : NSObject

/// 声网AppId
@property (nonatomic, copy) NSString *appId;
/// ChatGPT服务密钥
@property (nonatomic, copy) NSString *agoraServiceKey;
/// 讯飞AppId
@property (nonatomic, copy) NSString *hyAppId;
/// 讯飞AppKey
@property (nonatomic, copy) NSString *hyApiKey;
/// 讯飞AppSecret
@property (nonatomic, copy) NSString *hyApiSecret;
/// chatGPT接口地址
@property (nonatomic, copy) NSString *chatGPTApiUrl;

/// 语音转文字后是否直接向ChatGPT提问
@property (nonatomic, assign) BOOL autoQuestioning;
/// ChatGPT上下文缓存的最大消息数量
@property (nonatomic, assign) NSUInteger limitChatMessageCount;
/// 是否是调试模式，调试模式会打印额外的日志
@property (nonatomic, assign) BOOL debug;

@end

NS_ASSUME_NONNULL_END
