#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <dlfcn.h>

// 1. 声明私有接口
@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

// 2. 定义 Hook 组，专门针对延迟加载的 AudioSettings 模块
%group AudioSettingsHook

%hook RPCCAudioSettingsModuleViewController

- (void)loadView {
    // 强制替换为 0 尺寸的空白隐藏 View
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.alpha = 0.0;
    self.view = emptyView;
}

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.view.hidden = YES;
    [self.view removeFromSuperview];
}

%end

%end // end group

// 3. 构造函数：监听动态 Bundle 的加载
%ctor {
    @autoreleasepool {
        %init; // 初始化全局 Hook
        
        // 动态监听 Bundle 或类加载
        void (^initHook)(void) = ^{
            Class targetClass = objc_getClass("RPCCAudioSettingsModuleViewController");
            if (targetClass) {
                %init(AudioSettingsHook, RPCCAudioSettingsModuleViewController = targetClass);
            }
        };

        // 尝试直接初始化
        initHook();

        // 监听系统 NSBundleDidLoadNotification 通知，一旦 AudioSettings Bundle 被加载立刻注入
        [[NSNotificationCenter defaultCenter] addObserverForName:NSBundleDidLoadNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            initHook();
        }];
    }
}
