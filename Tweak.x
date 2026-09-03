#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// 1. 声明继承自 UIViewController，让编译器识别 view 属性
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

// 2. 声明容器私有接口
@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 3. 核心逻辑：直接拦截模块控制器
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

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    vc.view.hidden = YES;
    [vc.view removeFromSuperview];
}

%end

// 4. 拦截控制中心模块容器（从截图中的 CCUIContentModuleContentContainerView 根源拦截）
%hook CCUIContentModuleContainerViewController

- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *vc = (UIViewController *)self;
    NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
    
    if ([childCls containsString:@"RPCCAudioSettingsModuleViewController"] || 
        [childCls containsString:@"CCUISensorAttributionExpandedViewController"]) {
        vc.view.hidden = YES;
        vc.view.alpha = 0.0;
        vc.view.frame = CGRectZero;
        [vc.view removeFromSuperview];
    }
}

%end
