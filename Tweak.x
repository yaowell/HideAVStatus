#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 保留你验证有效的 loadView 剥离逻辑
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

// 2.【精准对位 FLEX】：沿视图树找到 UICollectionViewCell，强行压扁 frame 消除占位
%hook CCUIContentModuleContainerViewController

- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || 
            [childCls containsString:@"RPCCVideoSettings"]) {
            
            // 隐藏并清空 VC 本身的 view
            vc.view.hidden = YES;
            vc.view.alpha = 0.0;
            vc.view.frame = CGRectZero;
            [vc.view removeFromSuperview];
            
            // 向上寻找装载这个 VC 的 UICollectionViewCell，直接将 Cell 尺寸砍成 0
            UIView *parent = vc.view.superview;
            while (parent != nil) {
                if ([parent isKindOfClass:NSClassFromString(@"UICollectionViewCell")]) {
                    parent.hidden = YES;
                    parent.frame = CGRectZero;
                    parent.bounds = CGRectZero;
                    break;
                }
                parent = parent.superview;
            }
        }
    }
}

%end
