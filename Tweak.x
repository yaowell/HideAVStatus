#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 保留你验证成功的子 VC 视图剥离
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (CGSize)preferredContentSize {
    return CGSizeZero;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (CGSize)preferredContentSize {
    return CGSizeZero;
}
%end

// 2.【核心】：Hook 包裹它们的父容器 VC，让容器占用的物理尺寸直接归零
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    // 检查这个容器里装的是不是音视频 VC
    if (self.childViewControllers.count > 0) {
        UIViewController *child = self.childViewControllers.firstObject;
        NSString *cls = NSStringFromClass([child class]);
        if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
            return CGSizeZero; // 告诉网格引擎：我的尺寸是 0，不要给我留位子
        }
    }
    return %orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (self.childViewControllers.count > 0) {
        UIViewController *child = self.childViewControllers.firstObject;
        NSString *cls = NSStringFromClass([child class]);
        if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
            self.view.frame = CGRectZero;
            self.view.hidden = YES;
        }
    }
}

%end
