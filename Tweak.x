#import <UIKit/UIKit.h>

// 1. 显式接口声明
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 2. 拦截音频模块（麦克风模式）
%hook RPCCAudioSettingsModuleViewController

- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
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

// 3. 拦截视频模块（视讯效果）
%hook RPCCVideoSettingsModuleViewController

- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
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

// 4. 外层容器级强行隐藏（彻底防止空边框占位）
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
