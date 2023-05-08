//
//  CCChatGPTMessageList.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/8.
//

#import <Foundation/Foundation.h>

#import "CCChatGPTMessage.h"

NS_ASSUME_NONNULL_BEGIN

@interface CCChatGPTMessageList : NSObject

@property (nonatomic, assign) NSInteger limitCount;

@property (readonly) NSArray <CCChatGPTMessage *>*messages;

- (void)appendMessage:(CCChatGPTMessage *)message;

- (void)setSystem:(nullable CCChatGPTMessage *)message;

@end

NS_ASSUME_NONNULL_END
