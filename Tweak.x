#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1. 音频模块（你的原始代码，一字不改）
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

// 2. 视频模块（你的原始代码，一字不改）
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

// 3. 容器：隐藏 + 消除占位
%hook CCUIContentModuleContainerViewController
- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *child = self.childViewControllers.firstObject;
    if(!child) return;
    NSString *cls = NSStringFromClass([child class]);
    if(![cls containsString:@"RPCCAudioSettings"] && ![cls containsString:@"RPCCVideoSettings"]) return;

    // 先记住 cell 和 collectionView（removeFromSuperview 后就拿不到了）
    UIView *cell = self.view.superview;
    UICollectionView *cv = nil;
    UIView *v = cell;
    while(v) {
        if([v isKindOfClass:[UICollectionView class]]) {
            cv = (UICollectionView *)v;
            break;
        }
        v = v.superview;
    }

    // 你原来的隐藏逻辑，一字不改
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];

    // 关键：下一个 runloop 把 cell 高度压成 0，并通知 collectionView 重新布局
    if(cell && cv) {
        dispatch_async(dispatch_get_main_queue(), ^{
            CGRect f = cell.frame;
            f.size.height = 0;
            cell.frame = f;
            cell.hidden = YES;
            [cv.collectionViewLayout invalidateLayout];
        });
    }
}
%end