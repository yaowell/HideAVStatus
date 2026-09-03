#import <UIKit/UIKit.h>

// 1. 声明私有接口，避免编译报错
@interface CCUIAVControlsViewController : UIViewController
- (BOOL)_canShow;
- (BOOL)hasContent;
@end

@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2.【逻辑截断】拦截系统 AV 控制器，直接告诉系统“不需要显示”且“没有内容”
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
    self.view.alpha = 0.0;
    [self.view removeFromSuperview];
}

%end

// 3.【数据截断】拦截 Sensor 数据源，伪造状态为未激活
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

- (NSUInteger)sensorType {
    return 0;
}

%end

// 4.【容器剥离】拦截顶层 StatusBar 容器
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
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

// 5.【兜底隐藏】拦截一切相关的子视图渲染
%hook UIView

- (void)layoutSubviews {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"AVControls"] || 
        [className containsString:@"MicMode"] || 
        [className containsString:@"VideoEffects"] ||
        [className containsString:@"ControlsServerOrigin"]) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.frame = CGRectZero;
    }
}

%end
