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

#pragma mark - 1. 模块内部隐藏（兜底）
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
    self.view.hidden = YES;
    self.view.alpha = 0;
    [self.view removeFromSuperview];
}
%end

#pragma mark - 2. 核心：布局后消除占位（纯UI操作，不碰内部数据）
%hook CCUIModuleCollectionView

- (void)layoutSubviews {
    %orig;
    
    // 按垂直位置排序所有模块
    NSArray *sorted = [self.subviews sortedArrayUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
        return [@(a.frame.origin.y) compare:@(b.frame.origin.y)];
    }];
    
    CGFloat offset = 0;
    for (UIView *subview in sorted) {
        CGRect frame = subview.frame;
        frame.origin.y -= offset;
        
        // 识别目标模块容器
        BOOL isTarget = NO;
        UIResponder *resp = subview.nextResponder;
        if ([resp isKindOfClass:NSClassFromString(@"CCUIContentModuleContainerViewController")]) {
            UIViewController *container = (UIViewController *)resp;
            if (container.childViewControllers.count > 0) {
                id child = container.childViewControllers.firstObject;
                if (isTargetModule(child)) {
                    isTarget = YES;
                    offset += CGRectGetHeight(subview.frame);
                    frame.size.height = 0;
                    subview.hidden = YES;
                }
            }
        }
        
        subview.frame = frame;
    }
}

%end