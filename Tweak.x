#import <UIKit/UIKit.h>

// 声明私有接口，避免编译报错
@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 强制隐藏 View 的通用辅助函数
static void HideViewCompletely(UIView *view) {
    if (!view) return;
    view.hidden = YES;
    view.alpha = 0.0;
    view.userInteractionEnabled = NO;
    // 强制将其尺寸置零，防止占据控制中心顶部的布局空间
    CGRect frame = view.frame;
    frame.size.height = 0;
    view.frame = frame;
}

// 1. Hook 顶部状态栏控制器（持续在布局后刷新隐藏状态）
%hook CCUIOverlayStatusBarViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        HideViewCompletely(controlsView);
    }
}

%end

// 2. Hook 模块容器布局（直接匹配 AV / VideoEffects / MicMode 等模块类名）
%hook UIView

- (void)layoutSubviews {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"AVControls"] || 
        [className containsString:@"VideoEffects"] || 
        [className containsString:@"MicMode"] ||
        [className containsString:@"CCUIControlsServerOriginControl"]) {
        HideViewCompletely(self);
    }
}

%end
