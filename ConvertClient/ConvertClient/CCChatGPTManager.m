//
//  CCChatGPTManager.m
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import "CCChatGPTManager.h"
#import "CCChatGPTMessageList.h"

const CCChatGPTModel CCChatGPTModel_35 = @"gpt-3.5-turbo";
const CCChatGPTModel CCChatGPTModel_40 = @"gpt-4";

static NSString *CCChatGPTRoleUser = @"user";
static NSString *CCChatGPTRoleSystem = @"system";
static NSString *CCChatGPTRoleAssistant = @"assistant";

@interface CCChatGPTManager () <NSURLSessionDataDelegate>

@property (nonatomic, strong) CCConvertClientConfig *config;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, CCChatGPTResponseBlock>*requestDictionary;
@property (nonatomic, strong) CCChatGPTMessageList *messageList;
@property (nonatomic, strong) NSURLSession *session;

@end

@implementation CCChatGPTManager

+ (instancetype)shared
{
    static CCChatGPTManager *m = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        m = [[CCChatGPTManager alloc] init];
    });
    return m;
}

- (instancetype)init
{
    if (self = [super init]) {
        _model = CCChatGPTModel_35;
        _requestDictionary = [NSMutableDictionary dictionary];
        _messageList = [[CCChatGPTMessageList alloc] init];
        _session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration delegate:self delegateQueue:NSOperationQueue.mainQueue];
    }
    return self;
}

- (void)configClient:(CCConvertClientConfig *)config
{
    _config = config;
    _messageList.limitCount = _config.limitChatMessageCount;
}

- (void)appendSystemMessage:(NSString *)content
{
    CCChatGPTMessage *message = [[CCChatGPTMessage alloc] init];
    message.role = CCChatGPTRoleSystem;
    message.content = content;
    [_messageList setSystem:message];
}

- (void)sendQuestionToChatGPT:(NSString *)question response:(CCChatGPTResponseBlock)response
{
    if (!_config) {
        NSLog(@"chat gpt need setup config");
        return;
    }
    CCChatGPTMessage *message = [[CCChatGPTMessage alloc] init];
    message.role = CCChatGPTRoleUser;
    message.content = question;
    [_messageList appendMessage:message];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    request.HTTPMethod = @"POST";
    request.allHTTPHeaderFields = @{
        @"Content-Type": @"application/json",
        @"agora-service-key": _config.agoraServiceKey
    };
    request.URL = [NSURL URLWithString:_config.chatGPTApiUrl];
    
    NSMutableArray *messages = [NSMutableArray array];
    for (CCChatGPTMessage *message in _messageList.messages) {
        [messages addObject:@{
            @"role": message.role,
            @"content": message.content
        }];
    }
    NSDictionary *body = @{
        @"model": _model,
        @"messages": messages
    };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:NSJSONWritingFragmentsAllowed error:nil];
    NSURLSessionDataTask *task = [_session dataTaskWithRequest:request];
    [task resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.requestDictionary[@(task.taskIdentifier)] = response;
    });
}

- (NSArray *)messages
{
    return _messageList.messages;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        if (_requestDictionary[@(dataTask.taskIdentifier)]) {
            _requestDictionary[@(dataTask.taskIdentifier)](nil, error);
        }
    } else {
        CCChatGPTResponseUsage *usage = [[CCChatGPTResponseUsage alloc] init];
        usage.prompt_tokens = [dict[@"usage"][@"prompt_tokens"] integerValue];
        usage.completion_tokens = [dict[@"usage"][@"completion_tokens"] integerValue];
        usage.total_tokens = [dict[@"usage"][@"total_tokens"] integerValue];
        
        CCChatGPTResponse *response = [[CCChatGPTResponse alloc] init];
        response.questionId = dict[@"id"];
        response.answer = dict[@"answer"];
        response.model = dict[@"model"];
        response.object = dict[@"object"];
        response.answer = dict[@"answer"];
        response.created = [dict[@"created"] unsignedLongLongValue];
        response.usage = usage;
        
        // TODO: 消息要插入问题的后面，requestDictionary 就得额外存一下问题消息
        CCChatGPTMessage *message = [[CCChatGPTMessage alloc] init];
        message.content = response.answer;
        message.role = CCChatGPTRoleAssistant;
        [_messageList appendMessage:message];
        
        if (_requestDictionary[@(dataTask.taskIdentifier)]) {
            _requestDictionary[@(dataTask.taskIdentifier)](response, nil);
        }
    }
    _requestDictionary[@(dataTask.taskIdentifier)] = nil;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if (error && _requestDictionary[@(task.taskIdentifier)]) {
        _requestDictionary[@(task.taskIdentifier)](nil, error);
        _requestDictionary[@(task.taskIdentifier)] = nil;
    }
}

@end
