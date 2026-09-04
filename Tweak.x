#import <UIKit/UIKit.h>

// 明确继承自 UIViewController，解开 childViewControllers 和 view 属性
@interface CCUIContentModuleContainerViewController : UIViewController
@end

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 保持子 VC 的 View 剥离与尺寸归零
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

// 2. 将容器 VC 的尺寸和视图同步归零，让 AutoLayout 放弃留白
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    if (self.childViewControllers.count > 0) {
        UIViewController *child = self.childViewControllers.firstObject;
        NSString *cls = NSStringFromClass([child class]);
        if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
            return CGSizeZero;
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
