#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@class CCUIModuleCollectionView;

#pragma mark - 工具
static BOOL isTargetModule(id obj) {
    if(!obj) return NO;
    NSString *cls = NSStringFromClass([obj class]);
    return [cls containsString:@"RPCCAudioSettings"] || [cls containsString:@"RPCCVideoSettings"];
}

#pragma mark - 1. 模块内部隐藏（你的原始逻辑，去掉removeFromSuperview避免被布局重置）
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
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
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
}
%end

#pragma mark - 2. 布局后消除占位（纯UI位移，不碰内部数据）
%hook CCUIModuleCollectionView

- (void)layoutSubviews {
    %orig;
    
    UIView *container = (UIView *)self;
    NSArray *sorted = [container.subviews sortedArrayUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        return [@(a.frame.origin.y) compare:@(b.frame.origin.y)];
    }];
    
    CGFloat offset = 0;
    Class containerCls = NSClassFromString(@"CCUIContentModuleContainerViewController");
    
    for (UIView *subview in sorted) {
        CGRect frame = subview.frame;
        frame.origin.y -= offset;
        
        UIResponder *resp = subview.nextResponder;
        if ([resp isKindOfClass:containerCls]) {
            UIViewController *vc = (UIViewController *)resp;
            if (vc.childViewControllers.count > 0) {
                id child = vc.childViewControllers.firstObject;
                if (isTargetModule(child)) {
                    CGFloat h = CGRectGetHeight(subview.frame);
                    offset += h;
                    frame.size.height = 0;
                    subview.hidden = YES;
                }
            }
        }
        
        subview.frame = frame;
    }
}

%end