#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@interface CCUIContentModuleContainerViewController : UIViewController
@end

#pragma mark - 1. 音频模块（你的原始代码，一字不改，已验证能隐藏）
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

#pragma mark - 3. 消除占位：多次异步强制压缩，覆盖布局重置
%hook CCUIContentModuleContainerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    
    UIViewController *child = self.childViewControllers.firstObject;
    if(!child) return;
    NSString *cls = NSStringFromClass([child class]);
    if(![cls containsString:@"RPCCAudioSettings"] && ![cls containsString:@"RPCCVideoSettings"]) return;

    // 先记住 cell 指针（removeFromSuperview 后就拿不到了）
    UIView *cell = self.view.superview.superview;
    
    // 你的原始隐藏逻辑
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
    
    // 分三次异步强制压高度，覆盖系统布局重置
    if(cell) {
        // 第1次：当前 runloop 结束后
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect f = cell.frame;
            f.size.height = 0.01;
            cell.frame = f;
            cell.hidden = YES;
        });
        // 第2次：10ms 后（覆盖第一次布局重置）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CGRect f = cell.frame;
            f.size.height = 0.01;
            cell.frame = f;
            cell.hidden = YES;
        });
        // 第3次：100ms 后（覆盖最终布局刷新）
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CGRect f = cell.frame;
            f.size.height = 0.01;
            cell.frame = f;
            cell.hidden = YES;
        });
    }
}
%end