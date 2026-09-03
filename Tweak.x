#import <UIKit/UIKit.h>

// 1. 显式声明私有类，确保编译通过
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 2.【核心高度锁定】：强行将 HeaderPocket 的展开状态锁死为 NO
// 阻止控制中心顶部触发 Sensor 展开动画，直接固定在原生默认高度
%hook CCUIHeaderPocketView

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO);
}

- (void)setSensorAttributionExpanded:(BOOL)expanded animated:(BOOL)animated {
    %orig(NO, NO);
}

%end

// 3.【麦克风模块压扁】：隐藏 View 并将尺寸归零
%hook RPCCAudioSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    vc.view.alpha = 0.0;
    vc.view.frame = CGRectZero;
    [vc.view removeFromSuperview];
}

%end

// 4.【视频效果模块压扁】：隐藏 View 并将尺寸归零
%hook RPCCVideoSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewDidLoad {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    vc.view.alpha = 0.0;
    vc.view.frame = CGRectZero;
    [vc.view removeFromSuperview];
}

%end

// 5.【外层容器塌陷】：让网格布局引擎（GridEngine）拿不到任何占用尺寸
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

%end
