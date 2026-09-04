#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@class CCUIModuleCollectionViewController;

#pragma mark - 工具
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

#pragma mark - 视图隐藏兜底
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

#pragma mark - 核心：创建后立刻用系统原生方法移除
%hook CCUIModuleCollectionViewController

- (id)_setupAndAddModuleViewControllerToHierarchy:(id)viewController {
    id result = %orig(viewController);
    id selfId = self;
    
    if(containsTarget(result)) {
        NSLog(@"[HideAV] 移除模块: %@", NSStringFromClass([result class]));
        SEL removeSel = NSSelectorFromString(@"_removeAndTearDownModuleViewControllerFromHierarchy:");
        if([selfId respondsToSelector:removeSel]) {
            [selfId performSelector:removeSel withObject:result afterDelay:0.0];
        }
    }
    
    return result;
}

%end