//
//  CCChatGPTMessage.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CCChatGPTMessage : NSObject

@property (nonatomic, copy) NSString *role;
@property (nonatomic, copy) NSString *content;

@end

NS_ASSUME_NONNULL_END
