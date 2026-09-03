#import <UIKit/UIKit.h>

// 1. 显式声明继承关系，解决 self.view 编译报错
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

@interface CCUIModuleCollectionViewController : UIViewController
@property (nonatomic, assign) UIEdgeInsets additionalContentInset;
@end

// 2.【核心高度恢复】干掉控制中心顶部的 Sensor 预留口袋容器 (HeaderPocket)
%hook CCUIHeaderPocketView

- (CGRect)frame {
    CGRect rect = %orig;
    rect.size.height = 0; // 强制高度归零
    return rect;
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeZero;
}

- (void)setFrame:(CGRect)frame {
    frame.size.height = 0;
    %orig(frame);
}

%end

// 3.【防止下移】拦截控制中心滚动视图的顶部偏移量
%hook CCUIModuleCollectionViewController

- (UIEdgeInsets)_compactLayoutInset {
    UIEdgeInsets orig = %orig;
    orig.top = 0;
    return orig;
}

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(setAdditionalContentInset:)]) {
        self.additionalContentInset = UIEdgeInsetsZero;
    }
}

%end

// 4.【模块隐藏与尺寸压扁】
%hook RPCCAudioSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    self.view = emptyView;
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

%end

// 5. 外层 Module 容器级抹平
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
