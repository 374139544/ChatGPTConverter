//
//  ViewController.m
//  ChatGPTConverter
//
//  Created by 冯钊 on 2023/5/5.
//

#import "ViewController.h"
#import <ConvertClient/ConvertClient.h>

@interface ViewController () <CCConvertClientDelegate>

@property (weak, nonatomic) IBOutlet UILabel *qLabel;
@property (weak, nonatomic) IBOutlet UILabel *aLabel;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *path = [NSBundle.mainBundle pathForResource:@"ApiKey" ofType:@"strings"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    CCConvertClientConfig *config = [[CCConvertClientConfig alloc] init];
    config.agoraServiceKey = dict[@"agoraServiceKey"];
    config.appId = dict[@"appId"];
    config.hyAppId = dict[@"hyAppId"];
    config.hyApiKey = dict[@"hyApiKey"];
    config.hyApiSecret = dict[@"hyApiSecret"];
    config.chatGPTApiUrl = dict[@"chatGPTApiUrl"];
    config.autoQuestioning = YES;
    config.debug = YES;
    [CCConvertClient.shared configClient:config];
    
    CCConvertClient.shared.delegate = self;
    
    
    [CCConvertClient.shared sendQuestionToChatGPT:@"res" response:^(CCChatGPTResponse * _Nullable response, NSError * _Nullable error) {
            
    }];
}

- (IBAction)startAction
{
    [CCConvertClient.shared hyStart];
}

- (IBAction)endAction
{
    [CCConvertClient.shared hyFlush];
}

- (IBAction)stopAction
{
    [CCConvertClient.shared hyStop];
}

- (void)cc_converClientVoice2TextOnResult:(NSString *)result subEnd:(BOOL)subEnd
{
    _qLabel.text = result;
}

- (void)cc_converClientVoice2TextOnEnd:(NSString *)result
{
    _qLabel.text = result;
}

- (void)cc_converClientOnChatGPTAnswer:(CCChatGPTResponse *)response error:(NSError *)error
{
    _aLabel.text = response.answer;
}

@end