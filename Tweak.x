#import <UIKit/UIKit.h>

// 1. 在最顶端显式声明父类，解决 forward class 编译错误
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIModularControlCenterOverlayViewController : UIViewController
@end

// 2. 彻底禁用音频/视频控制模块的加载与渲染
%hook RPCCAudioSettingsModuleViewController

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
}

// 阻止其向父容器请求分配高度空间
- (BOOL)_canShowWhileLocked {
    return NO;
}

%end

%hook RPCCVideoSettingsModuleViewController

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
}

- (BOOL)_canShowWhileLocked {
    return NO;
}

%end

// 3. 拦截顶层容器，将顶部 Header 占位高度直接清零
%hook CCUIModularControlCenterOverlayViewController

- (void)viewWillLayoutSubviews {
    %orig;
    
    // 遍历 overlay 的子视图，将 Header 区域的高度清零，使下方的控制组件自然向上贴紧
    UIView *overlayView = self.view;
    for (UIView *subview in overlayView.subviews) {
        NSString *clsName = NSStringFromClass([subview class]);
        if ([clsName containsString:@"Header"] || [clsName containsString:@"Sensor"] || [clsName containsString:@"RPCC"]) {
            subview.hidden = YES;
            CGRect frame = subview.frame;
            frame.size.height = 0;
            subview.frame = frame;
        }
    }
}

%end
