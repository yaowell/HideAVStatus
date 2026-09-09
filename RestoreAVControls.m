#import <Foundation/Foundation.h>

static NSString * const kAudioModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";


static void RestoreModule(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableDictionary *plist =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (plist == nil) {
        NSLog(@"[HideAVControlsRestore] plist not found: %@", path);
        return;
    }

    // 恢复显示
    plist[@"SBIconVisibility"] = @YES;

    BOOL success =
        [plist writeToFile:path atomically:YES];

    if (!success) {
        NSLog(@"[HideAVControlsRestore] WRITE FAILED: %@", path);
        return;
    }

    [fm setAttributes:@{
        NSFilePosixPermissions : @0644
    }
       ofItemAtPath:path
             error:nil];

    NSLog(@"[HideAVControlsRestore] RESTORED: %@", path);
}


int main(int argc, char *argv[])
{
    @autoreleasepool {

        RestoreModule(kAudioModule);
        RestoreModule(kVideoModule);

    }

    return 0;
}