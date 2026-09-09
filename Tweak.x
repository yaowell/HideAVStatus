#import <Foundation/Foundation.h>

static NSString * const kManagedDir = @"/var/Managed Preferences/mobile";
static NSString * const kAudioModule = @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";
static NSString * const kVideoModule = @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

static void BMRestoreModule(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 如果目录不存在，先创建
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:kManagedDir isDirectory:&isDir]) {
        [fm createDirectoryAtPath:kManagedDir withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: @0755} error:nil];
    }

    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    if (plist == nil) {
        plist = [NSMutableDictionary dictionary];
    }

    // 强制设为 YES (true)，恢复显示
    plist[@"SBIconVisibility"] = @YES;

    BOOL success = [plist writeToFile:path atomically:YES];
    if (success) {
        [fm setAttributes:@{NSFilePosixPermissions: @0644} ofItemAtPath:path error:nil];
    }
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            BMRestoreModule(kAudioModule);
            BMRestoreModule(kVideoModule);
        }
    }
}
