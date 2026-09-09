#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString * const kManagedDir =
    @"/var/Managed Preferences/mobile";

static NSString * const kAudioModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";


static void BMHideModule(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    NSError *error = nil;

    // 确保 Managed Preferences/mobile 目录存在
    BOOL isDir = NO;

    if (![fm fileExistsAtPath:kManagedDir isDirectory:&isDir]) {

        BOOL created =
            [fm createDirectoryAtPath:kManagedDir
          withIntermediateDirectories:YES
                           attributes:@{
                               NSFilePosixPermissions : @0755
                           }
                                error:&error];

        if (!created) {
            NSLog(@"[HideReplayKitCC] create directory failed: %@",
                  error);

            return;
        }
    }

    // 读取原有 plist
    NSMutableDictionary *plist =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (plist == nil) {
        plist = [NSMutableDictionary dictionary];
    }

    // Cowabunga Lite 的 Hide 模式
    plist[@"SBIconVisibility"] = @NO;

    // 写入 plist
    BOOL success =
        [plist writeToFile:path atomically:YES];

    if (!success) {
        NSLog(@"[HideReplayKitCC] WRITE FAILED: %@",
              path);

        return;
    }

    // 确保系统进程可读
    [fm setAttributes:@{
        NSFilePosixPermissions : @0644
    }
       ofItemAtPath:path
             error:nil];

    NSLog(@"[HideReplayKitCC] HIDDEN: %@",
          path);
}


static void BMApply(void)
{
    BMHideModule(kAudioModule);
    BMHideModule(kVideoModule);
}


%ctor
{
    @autoreleasepool {

        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        BMApply();
    }
}