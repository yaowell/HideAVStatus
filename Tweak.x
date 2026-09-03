#import <UIKit/UIKit.h>

// 1. 显式声明接口，防止编译报错
@interface CCUIAVControlsViewController : UIViewController
- (BOOL)_canShow;
- (BOOL)hasContent;
@end

@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2.【彻底熔断】拦截 AV 控制器的显示条件判断
%hook CCUIAVControlsViewController

- (BOOL)_canShow {
    return NO;
}

- (BOOL)hasContent {
    return NO;
}

// 在加载 View 的瞬间直接替换成 0 尺寸的透明空 View
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.alpha = 0.0;
    self.view = emptyView;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

%end

// 3.【强行拔除】控制中心顶部容器 View 拦截
%hook CCUIOverlayStatusBarViewController

- (void)viewDidLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        if (controlsView) {
            controlsView.hidden = YES;
            controlsView.alpha = 0.0;
            controlsView.frame = CGRectZero;
            [controlsView removeFromSuperview];
        }
    }
}

%end
