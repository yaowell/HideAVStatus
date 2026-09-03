#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 强行重写固有尺寸，让 Auto Layout 布局引擎认为模块尺寸为 0
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

// 2. 强行塌陷外层容器的尺寸并禁用布局边距
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || 
            [childCls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero; // 尺寸归零，让父容器自动塌陷
        }
    }
    return %orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || 
            [childCls containsString:@"RPCCVideoSettings"]) {
            vc.view.hidden = YES;
            vc.view.alpha = 0.0;
            vc.view.frame = CGRectZero;
            [vc.view removeFromSuperview];
        }
    }
}

%end

// 3. 强行清空包含这两块的顶部 StackView 的边距 padding
%hook UIStackView

- (void)layoutSubviews {
    %orig;
    for (UIView *subview in self.arrangedSubviews) {
        NSString *clsName = NSStringFromClass([subview class]);
        if ([clsName containsString:@"RPCCAudioSettings"] || 
            [clsName containsString:@"RPCCVideoSettings"] ||
            [clsName containsString:@"CCUIContentModuleContentContainerView"]) {
            
            // 检查子视图控制器类名
            for (UIView *child in subview.subviews) {
                NSString *childCls = NSStringFromClass([child class]);
                if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
                    subview.hidden = YES;
                    subview.frame = CGRectZero;
                    [self removeArrangedSubview:subview]; // 物理剔除布局栈
                    [subview removeFromSuperview];
                }
            }
        }
    }
}

%end
