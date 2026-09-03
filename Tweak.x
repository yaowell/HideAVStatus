#import <UIKit/UIKit.h>

// 1. 显式声明接口，彻底解决 property 'view' cannot be found 编译错误
@interface CCUIAVControlsViewController : UIViewController
@end

@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2. 拦截 Sensor 数据源：让系统以为没有任何 App 在使用麦克风/摄像头
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end

// 3. 拦截 AV 控制器：阻止视图加载并强行清空
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
    if (self.view.superview) {
        [self.view removeFromSuperview];
    }
}

- (CGSize)preferredContentSize {
    // 强制把模块所需尺寸设为零，防止占位
    return CGSizeZero;
}

%end

// 4. 拦截控制中心顶部栏：隐藏容器
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        if (controlsView) {
            controlsView.hidden = YES;
            controlsView.alpha = 0.0;
        }
    }
}

%end
