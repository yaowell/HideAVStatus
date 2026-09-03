#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1.【阻止动态挂载】：当系统尝试将音视频模块作为 ChildViewController 重新添加时，直接拦下
%hook UIViewController

- (void)addChildViewController:(UIViewController *)childController {
    NSString *clsName = NSStringFromClass([childController class]);
    if ([clsName containsString:@"RPCCAudioSettings"] || 
        [clsName containsString:@"RPCCVideoSettings"]) {
        // 拒绝对这两个模块进行挂载，直接返回，切断“模块又出来”的链条
        return;
    }
    %orig;
}

%end

// 2.【绝杀网格 Engine】：不给网格引擎分配任何 Frame 和尺寸
%hook CCUIContentModuleContainerViewController

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

%end

// 3.【绝杀状态拉伸】：阻止 Header 触发高度扩展
%hook CCUIHeaderPocketView

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO);
}

- (void)setSensorAttributionExpanded:(BOOL)expanded animated:(BOOL)animated {
    %orig(NO, NO);
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

%end

// 4.【模块控制器本身防守】
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end
