#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

static void BMRestoreDefault(NSString *domain)
{
    CFStringRef appID = (__bridge CFStringRef)domain;

    CFPreferencesSetValue(
        CFSTR("SBIconVisibility"),
        NULL,
        appID,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );

    CFPreferencesSynchronize(
        appID,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );

    NSLog(@"[HideAVControls] Restored default: %@", domain);
}

int main(int argc, char *argv[])
{
    @autoreleasepool {

        BMRestoreDefault(
            @"com.apple.replaykit.AudioConferenceControlCenterModule"
        );

        BMRestoreDefault(
            @"com.apple.replaykit.VideoConferenceControlCenterModule"
        );
    }

    return 0;
}