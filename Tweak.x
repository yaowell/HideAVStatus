#import <Foundation/Foundation.h>

// 声明 iOS 系统原生的管理配置私有接口
@interface MCProfileConnection : NSObject
+ (instancetype)sharedConnection;
- (void)removePreferencesForDomain:(NSString *)domain; // 彻底清除某个域的限制
- (void)refreshManagedPreferences;                      // 强制刷新系统偏好
@end

static void BMRestoreViaSystemAPI(void) {
    // 1. 物理删除磁盘残留文件
    NSFileManager *fm = [NSFileManager defaultManager];
    [fm removeItemAtPath:@"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist" error:nil];
    [fm removeItemAtPath:@"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist" error:nil];

    // 2. 调用系统底层 API 强行抹除内存中的限制域
    Class mcClass = NSClassFromString(@"MCProfileConnection");
    if (mcClass && [mcClass respondsToSelector:@selector(sharedConnection)]) {
        MCProfileConnection *conn = [mcClass sharedConnection];
        
        // 清除 Audio 模块的管理偏好域
        if ([conn respondsToSelector:@selector(removePreferencesForDomain:)]) {
            [conn removePreferencesForDomain:@"com.apple.replaykit.AudioConferenceControlCenterModule"];
            [conn removePreferencesForDomain:@"com.apple.replaykit.VideoConferenceControlCenterModule"];
        }
        
        // 刷新偏好设置数据库
        if ([conn respondsToSelector:@selector(refreshManagedPreferences)]) {
            [conn refreshManagedPreferences];
        }
    }
}

%ctor {
    @autoreleasepool {
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
        if ([bundleID isEqualToString:@"com.apple.springboard"]) {
            BMRestoreViaSystemAPI();
        }
    }
}
