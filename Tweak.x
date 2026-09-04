#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@class CCUIModuleInstanceManager;

#pragma mark - 工具
static BOOL isTargetModule(id obj) {
    if(!obj) return NO;
    NSString *cls = NSStringFromClass([obj class]);
    return [cls containsString:@"RPCCAudioSettings"] || [cls containsString:@"RPCCVideoSettings"];
}

#pragma mark - 1. 视图隐藏兜底
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

#pragma mark - 2. 根源消除：模块实例 getter 过滤，布局系统直接看不到
%hook CCUIModuleInstanceManager

- (id)moduleInstances {
    NSArray *original = %orig;
    if(!original) return original;
    
    NSMutableArray *filtered = [original mutableCopy];
    BOOL changed = NO;
    for (id inst in [original copy]) {
        id vc = [inst valueForKey:@"viewController"];
        if (isTargetModule(vc)) {
            [filtered removeObject:inst];
            changed = YES;
        }
    }
    return changed ? filtered : original;
}

%end