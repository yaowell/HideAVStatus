#import <UIKit/UIKit.h>

// 1. 必须在所有 %hook 之前完整声明 Interface，不能依赖 Logos 的自动生成
@interface CCUIContentModuleContainerView : UIView
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;
@end

@interface CCUIModuleCollectionViewController : UIViewController
@end

// 2. 匹配逻辑
static BOOL isTargetModule(NSString *identifier) {
    if (!identifier) return NO;
    return [identifier isEqualToString:@"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
           [identifier isEqualToString:@"com.apple.replaykit.VideoConferenceControlCenterModule"] ||
           [identifier containsString:@"AudioConferenceControlCenter"] ||
           [identifier containsString:@"VideoConferenceControlCenter"];
}

// 3. 核心布局剔除
%hook CCUIModuleCollectionViewController

- (BOOL)_shouldShowModuleWithIdentifier:(NSString *)identifier {
    if (isTargetModule(identifier)) {
        return NO;
    }
    return %orig;
}

%end

// 4. 视图层兜底
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
