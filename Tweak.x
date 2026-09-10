#import <Foundation/Foundation.h>

static NSString * const kManagedDir =
    @"/var/Managed Preferences/mobile";

static NSString * const kAudioModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

static void BMHideModule(NSString *path)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    NSMutableDictionary *plist =
        [NSMutableDictionary dictionaryWithContentsOfFile:path];

    if (plist == nil) {
        plist = [NSMutableDictionary dictionary];
    }

    id visibility = plist[@"SBIconVisibility"];

    BOOL alreadyHidden =
        [visibility respondsToSelector:@selector(boolValue)] &&
        ![visibility boolValue];

    if (!alreadyHidden) {

        plist[@"SBIconVisibility"] = @NO;

        BOOL success =
            [plist writeToFile:path atomically:YES];

        if (!success) {
            NSLog(@"[HideReplayKitCC] WRITE FAILED: %@", path);
            return;
        }

        NSLog(@"[HideReplayKitCC] HIDDEN: %@", path);
    }

    NSDictionary *attributes =
        [fm attributesOfItemAtPath:path error:nil];

    NSNumber *permissions =
        attributes[NSFilePosixPermissions];

    if (permissions == nil ||
        [permissions unsignedShortValue] != 0644) {

        [fm setAttributes:@{
            NSFilePosixPermissions : @0644
        }
        ofItemAtPath:path
        error:nil];
    }
}

static void BMApply(void)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    BOOL isDir = NO;

    if (![fm fileExistsAtPath:kManagedDir
                  isDirectory:&isDir]) {

        NSError *error = nil;

        BOOL created =
            [fm createDirectoryAtPath:kManagedDir
          withIntermediateDirectories:YES
                           attributes:@{
                               NSFilePosixPermissions : @0755
                           }
                                error:&error];

        if (!created) {
            NSLog(@"[HideReplayKitCC] CREATE DIR FAILED: %@", error);
            return;
        }
    }

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