#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@interface CCUIContentModuleContainerViewController : UIViewController
@end

#pragma mark - 1. 音频模块（你的原始代码）
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
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 2. 视频模块（你的原始代码）
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
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 3. 容器层：布局源头返回 0 高度
%hook CCUIContentModuleContainerViewController

- (CGSize)preferredContentSize {
    UIViewController *child = self.childViewControllers.firstObject;
    if(child) {
        NSString *cls = NSStringFromClass([child class]);
        if([cls containsString:@"RPCCAudioSettings"] || [cls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero;
        }
    }
    return %orig;
}

- (void)viewDidLayoutSubviews {
    %orig;
    UIViewController *child = self.childViewControllers.firstObject;
    if(!child) return;
    NSString *cls = NSStringFromClass([child class]);
    if(![cls containsString:@"RPCCAudioSettings"] && ![cls containsString:@"RPCCVideoSettings"]) return;
    
    UIView *cell = self.view.superview.superview;
    if(cell) {
        CGRect f = cell.frame;
        f.size.height = 0.01;
        cell.frame = f;
        cell.hidden = YES;
    }
}

%end