//
//  CCChatGPTMessageList.m
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/8.
//

#import "CCChatGPTMessageList.h"

@interface CCChatGPTMessageList ()

@property (nonatomic, strong) NSMutableArray <CCChatGPTMessage *>*messageList;
@property (nonatomic, strong) CCChatGPTMessage *systemMessage;

@end

@implementation CCChatGPTMessageList

- (instancetype)init
{
    if (self = [super init]) {
        _limitCount = 30;
        _messageList = [NSMutableArray array];
    }
    return self;
}

- (void)setLimitCount:(NSInteger)limitCount
{
    if (limitCount < 1) {
        limitCount = 1;
    }
    _limitCount = limitCount;
    [self arrange];
}

- (NSArray<CCChatGPTMessage *> *)messages
{
    return [NSArray arrayWithArray:_messageList];
}

- (void)appendMessage:(CCChatGPTMessage *)message
{
    if (message) {
        [self.messageList addObject:message];
        [self arrange];
    }
}

- (void)setSystem:(CCChatGPTMessage *)message
{
    if (_systemMessage) {
        [_messageList removeObjectAtIndex:0];
        if (message) {
            [_messageList insertObject:message atIndex:0];
        }
    } else {
        [_messageList insertObject:message atIndex:0];
        [self arrange];
    }
    _systemMessage = message;
}

- (void)arrange
{
    if (_messageList.count > _limitCount) {
        NSInteger begin = _systemMessage ? 1 : 0;
        [_messageList removeObjectsInRange:NSMakeRange(begin, _messageList.count - _limitCount)];
    }
}

@end
