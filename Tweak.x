#import <UIKit/UIKit.h>

// 1. Hook 麦克风与视频效果控制器，直接让它们的 View 无法加载或保持隐藏
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end

// 2. 拦截 AV 控制模块视图（控制中心顶部两个长条）
%hook CCUIAVControlsViewController

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    [self.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

%end

// 3. 拦截控制中心顶部的 Sensor 状态容器
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        if (controlsView) {
            controlsView.hidden = YES;
            controlsView.alpha = 0.0;
            [controlsView removeFromSuperview];
        }
    }
}

%end
