#import <UIKit/UIKit.h>

// 1. 根据 FLEX 截图直接声明真实的私有类
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface CCUISensorAttributionExpandedViewController : UIViewController
@end

// 2.【精准拦截 1】：直接把音频设置模块（麦克风模式/视频效果）干掉
%hook RPCCAudioSettingsModuleViewController

- (void)loadView {
    // 强行替换为 0 尺寸空 View
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    self.view = emptyView;
}

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

%end

// 3.【精准拦截 2】：强行隐藏传感器展开归属视图
%hook CCUISensorAttributionExpandedViewController

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

%end

// 4.【数据层抹杀】：配合 SensorKit 数据隐藏
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end
