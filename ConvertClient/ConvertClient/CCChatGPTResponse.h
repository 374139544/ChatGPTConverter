//
//  CCChatGPTResponse.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCChatGPTResponseUsage : NSObject

@property (nonatomic, assign) NSInteger prompt_tokens;
@property (nonatomic, assign) NSInteger completion_tokens;
@property (nonatomic, assign) NSInteger total_tokens;

@end

@interface CCChatGPTResponse : NSObject

@property (nonatomic, copy) NSString *questionId;
@property (nonatomic, copy) NSString *answer;
@property (nonatomic, copy) NSString *model;
@property (nonatomic, copy) NSString *object;
@property (nonatomic, assign) uint64_t created;
@property (nonatomic, strong) CCChatGPTResponseUsage *usage;

@end

NS_ASSUME_NONNULL_END
