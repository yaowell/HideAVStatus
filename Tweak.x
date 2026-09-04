#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 保留你完全有效的 VC 视图彻底剥离逻辑
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

// 2. 核心：沿着视图链向上“强行抹平”所有父级容器的 Height 和 Frame
%hook CCUIContentModuleContainerViewController

- (void)viewDidLayoutSubviews {
    %orig;
    
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            
            // 隐藏当前 VC 的 View 并清空 Frame
            vc.view.hidden = YES;
            vc.view.frame = CGRectZero;
            [vc.view removeFromSuperview];
            
            // 向上递归遍历所有父级 View，强行把它们的尺寸全拉成 0，彻底压扁空白区域
            UIView *parent = vc.view.superview;
            while (parent != nil) {
                // 如果父视图的类名包含 CCUI 或者 Header，说明到了控制中心的容器层
                NSString *parentCls = NSStringFromClass([parent class]);
                
                // 将父视图的高度强制压扁成 0
                CGRect pFrame = parent.frame;
                pFrame.size.height = 0;
                parent.frame = pFrame;
                parent.clipsToBounds = YES;
                
                // 如果到了最外层的 PocketView，直接隐藏
                if ([parentCls containsString:@"HeaderPocket"] || [parentCls containsString:@"ModuleContainer"]) {
                    parent.hidden = YES;
                }
                
                parent = parent.superview;
            }
        }
    }
}

%end
