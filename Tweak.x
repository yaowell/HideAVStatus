#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@interface CCUIContentModuleContainerViewController : UIViewController
@end

#pragma mark - 1. 音频模块（你的原始代码，一字不改）
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

#pragma mark - 2. 视频模块（你的原始代码，一字不改）
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

#pragma mark - 3. 容器：只做高度压缩（dispatch 到下一个 runloop，不影响原布局）
%hook CCUIContentModuleContainerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    
    UIViewController *child = self.childViewControllers.firstObject;
    if(!child) return;
    NSString *cls = NSStringFromClass([child class]);
    if(![cls containsString:@"RPCCAudioSettings"] && ![cls containsString:@"RPCCVideoSettings"]) return;

    // 记住上层 cell（removeFromSuperview 后就拿不到了）
    UIView *cell = self.view.superview.superview;
    
    // 你的原始隐藏逻辑
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
    
    // 下一个 runloop 压缩 cell 高度，不干扰本次布局
    if(cell) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect f = cell.frame;
            f.size.height = 0.01;
            cell.frame = f;
            cell.hidden = YES;
        });
    }
}
%end