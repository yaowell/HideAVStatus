#import <UIKit/UIKit.h>

// 1. Hook 顶层指示器/Header 容器
%hook RPCCAudioSettingsModuleViewController
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
}
%end

// 2. 强行改变控制中心顶部 Header 的高度分布
%hook CCUIModularControlCenterOverlayViewController

- (void)viewWillLayoutSubviews {
    %orig;
    // 强制刷新主视图的 layout，消除顶部 margin
    UIView *overlayView = self.view;
    for (UIView *subview in overlayView.subviews) {
        NSString *cls = NSStringFromClass([subview class]);
        if ([cls containsString:@"Header"] || [cls containsString:@"Sensor"] || [cls containsString:@"Top"]) {
            subview.hidden = YES;
            subview.frame = CGRectZero;
        }
    }
}

%end
