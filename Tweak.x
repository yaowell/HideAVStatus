#import <UIKit/UIKit.h>

// 1. 声明私有类
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 2.【绝杀防崩】：直接让 Header View 认定 Sensor 处于非展开/非激活状态
// 这样控制中心就不会触发顶部的推顶/下移逻辑，直接维持原生默认高度！
%hook CCUIHeaderPocketView

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO); // 强制传 NO
}

%end

// 3.【模块物理压扁】：将音视频两个 View 的内容隐藏，尺寸设为 Zero
%hook RPCCAudioSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    self.view = emptyView;
}

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    vc.view.frame = CGRectZero;
    [vc.view removeFromSuperview];
}

%end

%hook RPCCVideoSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    self.view = emptyView;
}

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    vc.view.frame = CGRectZero;
    [vc.view removeFromSuperview];
}

%end

// 4.【外层容器屏蔽】
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero;
        }
    }
    return %orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            vc.view.hidden = YES;
            vc.view.frame = CGRectZero;
            [vc.view removeFromSuperview];
        }
    }
}

%end
