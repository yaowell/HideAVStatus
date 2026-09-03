#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

// 1. 强行 Hook 工厂构造函数，阻止控制器实例化
%hook RPCCAudioSettingsModuleViewController

+ (id)alloc {
    // 实例化时直接阻止或重定向（如果无法直接返回 nil，则在 init 阶段抹杀）
    return %orig;
}

- (id)init {
    self = %orig;
    if (self) {
        // 强制清空内部视图属性
        self.view.hidden = YES;
        self.view.alpha = 0.0;
        self.view.frame = CGRectZero;
    }
    return self;
}

// 2. 重写所有布局与绘制方法，彻底瘫痪渲染
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}

- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}

- (void)viewWillLayoutSubviews {
    %orig;
    self.view.frame = CGRectZero;
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

%end

// 3. 拦截容器视图层：直接匹配类名，在父 View 层面拒绝添加
%hook UIView

- (void)addSubview:(UIView *)view {
    NSString *clsName = NSStringFromClass([view class]);
    if ([clsName containsString:@"RPCCAudioSettings"] || 
        [clsName containsString:@"CCUISensorAttribution"]) {
        view.hidden = YES;
        view.frame = CGRectZero;
        return; // 直接拦截，拒绝添加到视图树
    }
    %orig(view);
}

%end
