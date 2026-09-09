#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

static CFStringRef const kAudioAppID =
    CFSTR("com.apple.replaykit.AudioConferenceControlCenterModule");

static CFStringRef const kVideoAppID =
    CFSTR("com.apple.replaykit.VideoConferenceControlCenterModule");

static CFStringRef const kVisibilityKey =
    CFSTR("SBIconVisibility");

static void RestoreDefault(CFStringRef appID)
{
    // 删除 SBIconVisibility
    // 不写 true，也不写 false
    // 删除后才是 Control Center 的 Default / 动态状态
    CFPreferencesSetValue(
        kVisibilityKey,
        NULL,
        appID,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );

    // 强制同步
    CFPreferencesSynchronize(
        appID,
        kCFPreferencesCurrentUser,
        kCFPreferencesAnyHost
    );

    NSLog(@"[HideReplayKitCC] DEFAULT RESTORED: %@", appID);
}

int main(int argc, char *argv[])
{
    @autoreleasepool {

        RestoreDefault(kAudioAppID);
        RestoreDefault(kVideoAppID);

        // 让 cfprefsd / SpringBoard 重新读取状态
        system("killall -9 cfprefsd 2>/dev/null");
        system("killall -9 SpringBoard 2>/dev/null");
    }

    return 0;
}