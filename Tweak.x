#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@class CCUIModuleCollectionViewController;

#pragma mark - 工具：判断是否目标模块
static BOOL isTargetModule(id obj) {
    if(!obj) return NO;
    NSString *cls = NSStringFromClass([obj class]);
    return [cls containsString:@"RPCCAudioSettings"] || [cls containsString:@"RPCCVideoSettings"];
}

static BOOL containsTarget(id container) {
    if(!container) return NO;
    if(isTargetModule(container)) return YES;
    NSArray *ch = [container valueForKey:@"childViewControllers"];
    for(id c in ch) if(isTargetModule(c)) return YES;
    return NO;
}

#pragma mark - 视图隐藏兜底（极端情况也看不见）
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

#pragma mark - 核心：添加模块时直接拦截（根源消除，无占位）
%hook CCUIModuleCollectionViewController

- (id)_setupAndAddModuleViewControllerToHierarchy:(id)viewController {
    if(containsTarget(viewController)) {
        NSLog(@"[HideAV] 已拦截模块: %@", NSStringFromClass([viewController class]));
        return nil;
    }
    return %orig(viewController);
}

%end