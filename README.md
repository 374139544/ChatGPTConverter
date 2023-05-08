# ChatGPTConverter

## 技术原理

讯飞转写插件的工作流程如下：

设置源语种和目标语种。
声网 SDK 通过麦克风来流式录音。
音频传递给讯飞转写插件。
插件把音频上传给语音转写服务，并下载语音转写结果。
解析语音转写结果，得到语音转写文本。

## 前提条件

iOS 开发环境需满足以下要求：
Xcode 9.0 或以上版本。
运行 iOS 11.0 或以上版本的真机（非模拟器）。

## 准备工作

使用声网 SDK 实现视频通话

讯飞转写&翻译插件插件需要与声网视频 SDK v4.x 搭配使用。参考以下文档集成视频 SDK v4.x 并实现基础的视频通话：
[实现视频通话（iOS）](https://docs.agora.io/cn/video-call-4.x/start_call_ios_ng%20?platform=iOS#创建项目)

## 购买和激活插件

在声网控制台[购买和激活](https://docs.agora.io/cn/extension_customer/get_extension?platform=All%20Platforms)讯飞转写&翻译插件。购买成功后，你会收到由讯飞提供的 appid、appKey 和 appSecret ，后续启动倾听时需要用到。

## 集成插件

参考如下步骤在你的项目中集成讯飞转写插件：
1. 进入声网控制台 > 云市场页面下载讯飞语音实时转写&翻译（中/英）的 iOS 插件包。
2. 解压文件夹，将所有 .framework 文件保存到你的项目文件夹下。
以如下项目结构为例，你可以把插件保存到 frameworks 路径下。

```.
├── <ProjectName>
│   ├── frameworks
├── <ProjectName>.xcodeproj
```

3. 修改`ConvertClient -> Build Settings -> Framework Search Paths`为`$(PROJECT_DIR)/../(Your Project Name)/(Your Project Name)/frameworks`

## 调用流程（iOS）

本节介绍插件相关接口的调用流程。接口的参数解释详见接口说明。

1. 初始化
```objectivec
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
```

2. 设置代理
```objectivec
CCConvertClient.shared.delegate = self;
```

3. 加入频道
```objectivec
[CCConvertClient.shared joinChannelByToken:nil channelId:@"agora_extension" info:nil uid:0 joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
            
}];
```

4. 启动倾听
```objectivec
[CCConvertClient.shared hyStart];
```

5. 结束音频获取结果
> 会话时可调用，调用后会先处理完音频和结果，再进入空闲，回调 "cc_converClientVoice2TextOnResult"。
```objectivec
[CCConvertClient.shared hyFlush];
```
SDK会通过 cc_converClientVoice2TextOnResult 回调返回语音转写结果。

6. 停止倾听
> 会话时可调用，调用后会先丢弃音频和结果，再进入空闲，回调 "cc_converClientVoice2TextOnEnd" 。
```objectivec
[CCConvertClient.shared hyStop];
```

7. 询问ChatGPT
> 如果`config.autoQuestioning = YES`，将对转录的文字内容像ChatGPT发出提问，提问的回答结果会通过`cc_converClientOnChatGPTAnswer`进行回调。

8. 用已有的文字内容向ChatGPT发出提问
```
[CCConvertClient.shared sendQuestionToChatGPT:@"请问iOS的内存管理是采用的什么机制" response:^(CCChatGPTResponse * _Nullable response, NSError * _Nullable error) {
    
}];
```