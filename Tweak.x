#import <UIKit/UIKit.h>

// 1. 声明控制中心核心布局容器
@interface CCUIModuleCollectionViewController : UIViewController
@property (nonatomic, assign) UIEdgeInsets additionalContentInset;
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 2.【清除顶部留白】强制重写控制中心集合视图的顶部内边距
%hook CCUIModuleCollectionViewController

- (UIEdgeInsets)_compactLayoutInset {
    UIEdgeInsets orig = %orig;
    orig.top = 0; // 强制抹平顶部边距
    return orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    // 强制归零 additionalContentInset
    if ([self respondsToSelector:@selector(setAdditionalContentInset:)]) {
        self.additionalContentInset = UIEdgeInsetsZero;
    }
    
    // 遍历 ScrollView 强行调整 offset 和 contentInset
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)self.view;
        UIEdgeInsets insets = scrollView.contentInset;
        if (insets.top > 0) {
            insets.top = 0;
            scrollView.contentInset = insets;
        }
    }
}

%end

// 3.【模块剥离】保持两个音视频模块的隐藏和尺寸归零
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView { self.view = [[UIView alloc] initWithFrame:CGRectZero]; self.view.hidden = YES; }
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView { self.view = [[UIView alloc] initWithFrame:CGRectZero]; self.view.hidden = YES; }
%end

// 4.【容器塌陷】外层 ModuleContainer 尺寸抹平
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
