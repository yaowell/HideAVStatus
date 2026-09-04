#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 保留你完全有效的 VC & View 实体剥离逻辑
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}
%end

%hook CCUIContentModuleContainerViewController
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

// 2.【核心改动】：干掉网格节点的物理 Height 计算
// 让容器向网格引擎（GridEngine）报告的尺寸直接为 Zero，消除网格空行
%hook CCUIContentModuleContainerViewController

- (CGSize)intrinsicContentSize {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero;
        }
    }
    return %orig;
}

- (CGRect)compactModeFrame {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            return CGRectZero;
        }
    }
    return %orig;
}

%end

// 3.【核心改动】：干掉顶部 ScrollView 的 topContentInset 伸缩偏移
%hook CCUIHeaderPocketView

- (void)setSensorAttributionExpanded:(BOOL)expanded animated:(BOOL)animated {
    %orig(NO, NO);
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (CGFloat)headerHeight {
    return 0.0;
}

%end
