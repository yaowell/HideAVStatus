#import <UIKit/UIKit.h>

// 1. 声明控制器与网格/布局私有接口
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 2.【绝杀源头】：拦截控制中心模块列表的获取，直接把这两个模块从数组里彻底删掉！
// 列表里没有它们，网格引擎（GridEngine）就不会为它们预留顶部的 Grid 行数！
%hook CCUIModuleCollectionViewController

- (NSArray *)moduleViewControllers {
    NSArray *origVCs = %orig;
    NSMutableArray *filteredVCs = [NSMutableArray array];
    
    for (UIViewController *vc in origVCs) {
        NSString *clsName = NSStringFromClass([vc class]);
        // 如果容器里装的是音视频模块，直接过滤丢弃
        if ([clsName containsString:@"CCUIContentModuleContainerViewController"]) {
            UIViewController *childVC = vc.childViewControllers.firstObject;
            NSString *childCls = NSStringFromClass([childVC class]);
            if ([childCls containsString:@"RPCCAudioSettings"] || 
                [childCls containsString:@"RPCCVideoSettings"]) {
                continue; // 跳过，不加入布局数组
            }
        }
        [filteredVCs addObject:vc];
    }
    return filteredVCs;
}

%end

// 3.【绝杀布局管理器】：如果系统单独查询某个模块的 Frame，强行返回 CGRectZero
%hook CCUIContentModuleContainerViewController

- (CGRect)compactModeFrame {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            return CGRectZero;
        }
    }
    return %orig;
}

- (CGSize)preferredContentSize {
    UIViewController *vc = (UIViewController *)self;
    if (vc.childViewControllers.count > 0) {
        NSString *childCls = NSStringFromClass([vc.childViewControllers.firstObject class]);
        if ([childCls containsString:@"RPCCAudioSettings"] || [childCls containsString:@"RPCCVideoSettings"]) {
            return CGSizeZero;
        }
    }
    return %orig;
}

%end

// 4.【兜底视图抹杀】
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView { self.view = [[UIView alloc] initWithFrame:CGRectZero]; self.view.hidden = YES; }
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView { self.view = [[UIView alloc] initWithFrame:CGRectZero]; self.view.hidden = YES; }
%end
