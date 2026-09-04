#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 隐藏音频模块（你的原始代码，一字不改）
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

// 2. 隐藏视频模块（你的原始代码，一字不改）
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

// 3. 消除占位：只加了往上压缩 cell 高度的逻辑
%hook CCUIContentModuleContainerViewController
- (void)viewWillLayoutSubviews {
    %orig;
    if (self.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([self.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] ||
            [childCls containsString:@"RPCCVideoSettings"]) {

            // 先记住上层视图（removeFromSuperview 后就拿不到了）
            UIView *sv = self.view.superview;

            // 你原来的隐藏逻辑
            self.view.hidden = YES;
            self.view.alpha = 0.0;
            self.view.frame = CGRectZero;
            [self.view removeFromSuperview];

            // 新增：把 cell 和更上层的高度全部压成 0
            for (int i = 0; sv && i < 4; i++) {
                CGRect f = sv.frame;
                f.size.height = 0;
                sv.frame = f;
                sv = sv.superview;
            }
        }
    }
}
%end