#import <UIKit/UIKit.h>

// 1. 声明底层私有模块接口
@interface CCUIModuleIdentifier : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@end

@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2.【源头截断】拦截控制中心模块加载，屏蔽 AV/Mic/Video 相关模块
%hook CCUIModuleRepository

- (id)_loadAllModuleMetadata {
    NSArray *modules = %orig;
    NSMutableArray *filteredModules = [NSMutableArray array];
    
    for (id module in modules) {
        NSString *moduleDescription = [module description];
        // 过滤掉所有包含 AVControls、MicMode、VideoEffects 的模块
        if (![moduleDescription containsString:@"AVControls"] && 
            ![moduleDescription containsString:@"MicMode"] && 
            ![moduleDescription containsString:@"VideoEffects"] &&
            ![moduleDescription containsString:@"ControlCenterUI.AV"]) {
            [filteredModules addObject:module];
        }
    }
    return filteredModules;
}

%end

// 3.【数据屏蔽】强制让系统以为 Sensor（麦克风/相机）状态未激活
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end

// 4.【UI 强制置空】防止残留视图渲染
%hook CCUIOverlayStatusBarViewController

- (void)viewWillLayoutSubviews {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        if (controlsView) {
            controlsView.hidden = YES;
            controlsView.alpha = 0.0;
            controlsView.frame = CGRectZero;
        }
    }
}

%end

// 5.【兜底隐藏】拦截所有可能弹出的 AV 视图容器
%hook UIView

- (void)setFrame:(CGRect)frame {
    NSString *className = NSStringFromClass([self class]);
    if ([className containsString:@"CCUIAVControls"] || 
        [className containsString:@"CCUIMicMode"] || 
        [className containsString:@"CCUIVideoEffects"]) {
        self.hidden = YES;
        self.alpha = 0.0;
        %orig(CGRectZero);
        return;
    }
    %orig(frame);
}

%end
