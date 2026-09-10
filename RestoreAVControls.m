#import <Foundation/Foundation.h>

static NSString * const kManagedDir =
    @"/var/Managed Preferences/mobile";

static NSString * const kAudioPath =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoPath =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

static void BMRestorePlist(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:path]) {
        NSLog(@"[HideAVControls] plist not found: %@", path);
        return;
    }

    NSMutableDictionary *plist =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (!plist) {
        NSLog(@"[HideAVControls] failed to read: %@", path);
        return;
    }

    if (plist[@"SBIconVisibility"] != nil) {

        [plist removeObjectForKey:@"SBIconVisibility"];

        BOOL success =
            [plist writeToFile:path atomically:YES];

        if (!success) {
            NSLog(@"[HideAVControls] FAILED TO RESTORE: %@", path);
            return;
        }

        [fm setAttributes:@{
            NSFilePosixPermissions : @0644
        }
        ofItemAtPath:path
        error:nil];

        NSLog(@"[HideAVControls] RESTORED DEFAULT: %@", path);

    } else {

        NSLog(@"[HideAVControls] already default: %@", path);
    }
}

int main(int argc, char *argv[])
{
    @autoreleasepool {

        BMRestorePlist(kAudioPath);
        BMRestorePlist(kVideoPath);
    }

    return 0;
}