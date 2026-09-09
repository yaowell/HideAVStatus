#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// 声明系统的 ManagedConfiguration 私有接口
@interface MCProfileConnection : NSObject
+ (instancetype)sharedConnection;
- (void)refreshManagedPreferences;
@end

static NSString * const kAudioModule = @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";
static NSString * const kVideoModule = @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

// 强行清理硬盘上的 plist 文件
static void BMCleanupPlists(void) {
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:kAudioModule error:nil];
    [fm removeItemAtPath:kVideoModule error:nil];
}

// 强制刷新系统内存里的配置缓存
static void BMForceRefreshSystemPreferences(void) {
    BMCleanupPlists();

    // 1. 通过系统 MCProfileConnection 强行刷内存配置
    Class mcClass = NSClassFromString(@"MCProfileConnection");
    if (mcClass && [mcClass respondsToSelector:@selector(sharedConnection)]) {
        MCProfileConnection *conn = [mcClass sharedConnection];
        if ([conn respondsToSelector:@selector(refreshManagedPreferences)]) {
            [conn refreshManagedPreferences];
        }
    }

    // 2. 发送系统层级的偏好设置变更通知
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFSTR("com.apple.managedconfiguration.profilelistchanged"),
        NULL,
        NULL,
        YES
    );
}

%hook CCUIHeaderPocketView
- (void)layoutSubviews {
    %orig;
    // 只要控制中心准备展开 layout，就强行触发一次刷新
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BMForceRefreshSystemPreferences();
    });
}
%end

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            BMForceRefreshSystemPreferences();
        }
    }
}
