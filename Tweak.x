#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

static BOOL isTargetModule(id obj) {
    if(!obj) return NO;
    NSString *cls = NSStringFromClass([obj class]);
    return [cls containsString:@"RPCCAudioSettings"] || [cls containsString:@"RPCCVideoSettings"];
}

static id getIvar(id obj, NSString *key) {
    return [obj valueForKey:key];
}

static void setIvar(id obj, NSString *key, id val) {
    [obj setValue:val forKey:key];
}

#pragma mark - 1. 视图隐藏
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

#pragma mark - 2. 数据源层：过滤模块实例
%hook CCUIModuleCollectionViewController

- (void)_populateModuleViewControllers {
    %orig;
    
    id selfId = self;
    id mgr = getIvar(selfId, @"_moduleManager");
    if(!mgr) return;
    
    NSArray *instances = getIvar(mgr, @"moduleInstances");
    if(!instances) return;
    
    NSMutableArray *filtered = [instances mutableCopy];
    BOOL changed = NO;
    for(id inst in [instances copy]) {
        id vc = getIvar(inst, @"viewController");
        if(isTargetModule(vc)) {
            [filtered removeObject:inst];
            changed = YES;
            NSLog(@"[HideAV] 移除模块实例: %@", NSStringFromClass([vc class]));
        }
    }
    
    if(changed) {
        setIvar(mgr, @"moduleInstances", filtered);
        [selfId performSelector:@selector(_updateModuleControllers) withObject:nil afterDelay:0.01];
    }
}

%end

#pragma mark - 3. 布局层：大小归零
%hook CCUIModuleCollectionViewController

- (CGSize)layoutView:(id)layoutView layoutSizeForSubview:(id)subview {
    CGSize size = %orig;
    
    UIResponder *r = subview;
    while(r) {
        if([r isKindOfClass:[UIViewController class]]) {
            if(isTargetModule(r)) {
                NSLog(@"[HideAV] 布局大小归零: %@", NSStringFromClass([r class]));
                return CGSizeZero;
            }
            break;
        }
        r = r.nextResponder;
    }
    
    Class containerCls = NSClassFromString(@"CCUIContentModuleContainerViewController");
    if([r isKindOfClass:containerCls]) {
        id child = [(UIViewController *)r childViewControllers].firstObject;
        if(isTargetModule(child)) {
            NSLog(@"[HideAV] 容器布局大小归零: %@", NSStringFromClass([child class]));
            return CGSizeZero;
        }
    }
    
    return size;
}

%end