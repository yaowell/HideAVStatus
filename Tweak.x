#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 拦截音频模块：把 preferredContentSize 强行重写为 Zero
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

// 2. 拦截视频模块：把 preferredContentSize 强行重写为 Zero
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

// 3. 拦截容器及 UIStackView 布局：物理移除节点并让尺寸塌陷
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || 
            [childCls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero; // 尺寸彻底归零，触发面板重新计算总高度
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

// 4. 从 Auto Layout 的 ArrangedSubviews 布局栈中直接拔除
%hook UIStackView

- (void)layoutSubviews {
    %orig;
    for (UIView *subview in [self.arrangedSubviews copy]) {
        NSString *clsName = NSStringFromClass([subview class]);
        if ([clsName containsString:@"RPCCAudioSettings"] || 
            [clsName containsString:@"RPCCVideoSettings"]) {
            subview.hidden = YES;
            subview.frame = CGRectZero;
            [self removeArrangedSubview:subview]; // 从 StackView 布局计算中抹除
            [subview removeFromSuperview];
        }
    }
}

%end
