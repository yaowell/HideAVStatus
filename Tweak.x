#import <UIKit/UIKit.h>

// 1. 声明私有类接口，防止 Clang 报错
@interface CCUIModuleIdentifier : NSObject
@property (nonatomic, copy, readonly) NSString *identifier;
@end

@interface CCUIModuleFactory : NSObject
+ (id)moduleForIdentifier:(CCUIModuleIdentifier *)identifier;
@end

@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

// 2.【绝杀一】：在工厂创建模块阶段直接拦截，返回 nil（源头杀，不给建立 UI 的机会）
%hook CCUIModuleFactory

+ (id)moduleForIdentifier:(CCUIModuleIdentifier *)identifier {
    NSString *idStr = [identifier description];
    if ([idStr containsString:@"AVControls"] || 
        [idStr containsString:@"MicMode"] || 
        [idStr containsString:@"VideoEffects"] ||
        [idStr containsString:@"com.apple.control-center.AVControls"]) {
        return nil; // 强行返回空，彻底取消该模块创建
    }
    return %orig;
}

%end

// 3.【绝杀二】：封杀 Sensor 动态广播（欺骗系统没有 App 在用麦克风/相机）
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

- (NSUInteger)sensorType {
    return 0;
}

%end

// 4.【绝杀三】：强行把顶层动态占位容器的尺寸抹成 0，防止留白
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
