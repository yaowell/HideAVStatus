#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 精准干掉麦克风模块：视图加不进来，尺寸置零
%hook RPCCAudioSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewWillLayoutSubviews {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
}

%end

// 2. 精准干掉视频效果模块：视图加不进来，尺寸置零
%hook RPCCVideoSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewWillLayoutSubviews {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
}

%end

// 3. 拦截顶层 Pocket 展开动画，防止整块面板下移
%hook CCUIHeaderPocketView

- (void)setSensorAttributionExpanded:(BOOL)expanded animated:(BOOL)animated {
    %orig(NO, NO);
}

%end
