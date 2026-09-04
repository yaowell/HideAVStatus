#import <UIKit/UIKit.h>

// 补充接口声明，让编译器知道它们继承自 UIViewController（拥有 view 属性）
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIModuleCollectionViewController : UIViewController
@end

@interface SBUISA_systemApertureLayoutGuide : NSObject
- (CGRect)layoutFrame;
@end

// 1. 彻底拦截 VC 的生命周期，禁止视图装载
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
}
%end

// 2.【核心】：直接禁止控制中心把这两个 VC 注册进模块列表，从根源清空 Item 占位
%hook CCUIModuleCollectionViewController

- (void)addChildViewController:(UIViewController *)childController {
    NSString *cls = NSStringFromClass([childController class]);
    // 只要是音视频卡片的 VC，拒绝加入容器
    if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
        return;
    }
    %orig;
}

%end

// 3. 辅助防线：干掉灵动岛/SystemAperture 动态卡片的布局引导线
%hook SBUISA_systemApertureLayoutGuide
- (CGRect)layoutFrame {
    return CGRectZero;
}
%end
