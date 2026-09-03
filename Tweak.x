#import <UIKit/UIKit.h>

// 1. 声明私有类，避免 Clang 编译报错
@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2.【核心截断】 Hook 控制中心顶部状态栏视图
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        if (controlsView) {
            controlsView.hidden = YES;
            controlsView.alpha = 0.0;
            // 直接拔除父视图，强行阻止渲染
            [controlsView removeFromSuperview];
        }
    }
}

%end

// 3.【视图拦截】直接拦截系统 UI 节点的尺寸和隐藏状态
%hook UIView

- (void)layoutSubviews {
    %orig;
    NSString *className = NSStringFromClass([self class]);
    // 匹配麦克风模式/视频效果等一切相关 UI 控件
    if ([className containsString:@"AVControls"] || 
        [className containsString:@"SensorActivity"] || 
        [className containsString:@"ControlsServerOrigin"] ||
        [className containsString:@"MicMode"] ||
        [className containsString:@"VideoEffects"]) {
        self.hidden = YES;
        self.alpha = 0.0;
        self.frame = CGRectZero;
    }
}

%end

// 4.【数据拦截】截断传感器状态激活标记
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end
