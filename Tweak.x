#import <UIKit/UIKit.h>

// 判断是否为需要隐藏的录音/视频控制中心模块 ID
static BOOL isTargetModule(NSString *identifier) {
    if (!identifier) return NO;
    return [identifier isEqualToString:@"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
           [identifier isEqualToString:@"com.apple.replaykit.VideoConferenceControlCenterModule"] ||
           [identifier containsString:@"AudioConferenceControlCenter"] ||
           [identifier containsString:@"VideoConferenceControlCenter"];
}

// 1. 核心绝杀：在布局配置/数据源中直接剔除模块（下方组件会自动顶上去，不留空白）
%hook CCUIModuleCollectionViewController

- (BOOL)_shouldShowModuleWithIdentifier:(NSString *)identifier {
    if (isTargetModule(identifier)) {
        return NO;
    }
    return %orig;
}

%end

// 2. 兜底保护：如果容器层依然尝试渲染 View，直接强制隐藏并归零
%hook CCUIContentModuleContainerView

- (void)setFrame:(CGRect)frame {
    if (isTargetModule(self.moduleIdentifier)) {
        %orig(CGRectZero);
        self.hidden = YES;
        return;
    }
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (isTargetModule(self.moduleIdentifier)) {
        self.hidden = YES;
        self.frame = CGRectZero;
    }
}

%end
