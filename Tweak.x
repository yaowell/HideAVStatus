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

#pragma mark - 1. 视图隐藏（你的原始逻辑，保留）
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

#pragma mark - 2. 数据源层：模块填充后过滤掉目标模块
%hook CCUIModuleCollectionViewController

- (void)_populateModuleViewControllers {
    %orig;
    
    id mgr = [self valueForKey:@"_moduleManager"];
    if(!mgr) return;
    
    // 拿到所有模块实例
    NSArray *instances = [mgr valueForKey:@"moduleInstances"];
    if(!instances) return;
    
    NSMutableArray *filtered = [instances mutableCopy];
    BOOL changed = NO;
    for(id inst in [instances copy]) {
        id vc = [inst valueForKey:@"viewController"];
        if(isTargetModule(vc)) {
            [filtered removeObject:inst];
            changed = YES;
            NSLog(@"[HideAV] 移除模块实例: %@", NSStringFromClass([vc class]));
        }
    }
    
    if(changed) {
        [mgr setValue:filtered forKey:@"moduleInstances"];
        // 触发重新布局
        [self performSelector:@selector(_updateModuleControllers) withObject:nil afterDelay:0.01];
    }
}

%end

#pragma mark - 3. 布局层：目标模块大小强制归零
%hook CCUIModuleCollectionViewController

- (CGSize)layoutView:(id)layoutView layoutSizeForSubview:(id)subview {
    CGSize size = %orig;
    
    // 沿着子视图找内部控制器
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
    
    // 再找容器里的子控制器
    if([r isKindOfClass:NSClassFromString(@"CCUIContentModuleContainerViewController")]) {
        id child = [(UIViewController *)r childViewControllers].firstObject;
        if(isTargetModule(child)) {
            NSLog(@"[HideAV] 容器布局大小归零: %@", NSStringFromClass([child class]));
            return CGSizeZero;
        }
    }
    
    return size;
}

%end