//
//  CCVoice2TextManager.h
//  ConvertClient
//
//  Created by 冯钊 on 2023/5/6.
//

#import <Foundation/Foundation.h>
#import "CCConvertClient.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CCVoice2TextManagerDelegate <NSObject>
@optional
- (void)cc_voice2TextManagerOnResult:(NSString *)result subEnd:(BOOL)subEnd;
- (void)cc_voice2TextManagerOnEnd;
- (void)cc_voice2TextManagerOnError:(int)error message:(NSString *)message;

@end

@interface CCVoice2TextManager : NSObject

@property (class, readonly) CCVoice2TextManager *shared;
@property (nonatomic, weak) id<CCVoice2TextManagerDelegate> delegate;

- (void)configClient:(CCConvertClientConfig *)config;

- (void)hyStart;
- (void)hyFlush;
- (void)hyStop;

@end

NS_ASSUME_NONNULL_END
