#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <unistd.h>

static NSString * const kAudioModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

static void BMHideModule(NSString *path)
{
    NSMutableDictionary *plist =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (plist == nil) {
        plist = [NSMutableDictionary dictionary];
    }

    // 设置为 Cowabunga Lite 的隐藏对应值
    plist[@"SBIconVisibility"] = @NO;

    BOOL success = [plist writeToFile:path atomically:YES];

    NSLog(@"[HideReplayKitCC] %@ : %@",
          path,
          success ? @"HIDDEN" : @"WRITE FAILED");
}

static void BMApply(void)
{
    BMHideModule(kAudioModule);
    BMHideModule(kVideoModule);
}

%ctor
{
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        /*
         * 在 SpringBoard 初始化时写入文件。
         * 不 Hook UI，不循环监听，零常驻功耗。
         */
        BMApply();
    }
}
