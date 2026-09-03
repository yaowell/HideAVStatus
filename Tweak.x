#import <UIKit/UIKit.h>

@interface CCUIModuleRepository : NSObject
@end

// 1.【绝杀模块注册】：在 Repository 扫描/加载模块列表时，直接过滤掉音视频控制模块
%hook CCUIModuleRepository

- (id)_loadModuleWithIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"AudioSettings"] || 
        [identifier containsString:@"VideoSettings"] ||
        [identifier containsString:@"com.apple.replaykit"]) {
        return nil; // 强行返回 nil，从系统模块仓库中删除
    }
    return %orig;
}

- (BOOL)isModuleSupportedWithIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"AudioSettings"] || 
        [identifier containsString:@"VideoSettings"] ||
        [identifier containsString:@"com.apple.replaykit"]) {
        return NO; // 告诉系统当前设备/环境不支持该模块
    }
    return %orig;
}

%end

// 2.【绝杀 UI 布局扩展】：锁定顶部 Header 不产生拉伸
%hook CCUIHeaderPocketView

- (BOOL)isSensorAttributionActive {
    return NO;
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO);
}

%end
