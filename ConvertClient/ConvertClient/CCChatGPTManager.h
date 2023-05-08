//
//  CCChatGPTManager.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import "CCChatGPTResponse.h"
#import "CCChatGPTMessage.h"
#import "CCConvertClient.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString *CCChatGPTModel;
const extern CCChatGPTModel CCChatGPTModel_35;
const extern CCChatGPTModel CCChatGPTModel_40;

typedef void(^CCChatGPTResponseBlock)(CCChatGPTResponse * _Nullable response, NSError * _Nullable error);

@interface CCChatGPTManager : NSObject

+ (instancetype)shared;

@property (nonatomic, copy) CCChatGPTModel model;
@property (readonly) NSArray <CCChatGPTMessage *>*messages;

- (void)configClient:(CCConvertClientConfig *)config;

- (void)appendSystemMessage:(NSString *)content;
- (void)sendQuestionToChatGPT:(NSString *)question response:(CCChatGPTResponseBlock)response;

@end

NS_ASSUME_NONNULL_END
