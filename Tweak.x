#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

// 1. 拦截系统读取偏好设置的底层 API，强行给这两个 Module 返回 NO (False)
%hookf(Boolean, CFPreferencesGetAppBooleanValue, CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat) {
    if (key && applicationID) {
        NSString *keyStr = (__bridge NSString *)key;
        NSString *appIDStr = (__bridge NSString *)applicationID;
        
        if ([keyStr isEqualToString:@"SBIconVisibility"]) {
            if ([appIDStr isEqualToString:@"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
                [appIDStr isEqualToString:@"com.apple.replaykit.VideoConferenceControlCenterModule"]) {
                if (keyExistsAndHasValidFormat) *keyExistsAndHasValidFormat = true;
                return false; // 强行返回 false
            }
        }
    }
    return %orig(key, applicationID, keyExistsAndHasValidFormat);
}

// 2. 插件加载时，直接给系统磁盘配置持久化写入 SBIconVisibility = false
%ctor {
    @autoreleasepool {
        CFStringRef key = CFSTR("SBIconVisibility");
        CFStringRef audioID = CFSTR("com.apple.replaykit.AudioConferenceControlCenterModule");
        CFStringRef videoID = CFSTR("com.apple.replaykit.VideoConferenceControlCenterModule");

        // 写入 Audio 模块
        CFPreferencesSetAppValue(key, kCFBooleanFalse, audioID);
        CFPreferencesAppSynchronize(audioID);

        // 写入 Video 模块
        CFPreferencesSetAppValue(key, kCFBooleanFalse, videoID);
        CFPreferencesAppSynchronize(videoID);
    }
}
