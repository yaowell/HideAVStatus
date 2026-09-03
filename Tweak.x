#import <UIKit/UIKit.h>

// 1. 拦截底层传感器（Sensor）数据源：直接告诉系统“没有 App 在使用麦克风/相机”
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

- (NSUInteger)sensorType {
    return 0; // 屏蔽类型
}

%end

// 2. 拦截系统 AV 路由与模块状态管理器
%hook CCUIAVControlsViewController

- (BOOL)_canShow {
    return NO;
}

- (BOOL)hasContent {
    return NO;
}

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

%end

// 3. 拦截顶层容器：将包含了这两个控件的 Header View 强制隐藏
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
    %orig;
    // 取得 controlsView 容器直接做销毁/隐藏
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *cView = [self performSelector:@selector(controlsView)];
        if (cView) {
            cView.hidden = YES;
            cView.alpha = 0.0;
            cView.frame = CGRectZero;
        }
    }
}

%end
