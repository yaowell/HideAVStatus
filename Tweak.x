#import <UIKit/UIKit.h>

// 1. 声明底层私有 XPC & 服务端接口
@interface CCUIControlsServer : NSObject
@end

@interface AVControlsBaseViewController : UIViewController
@end

// 2.【核心绝杀】：拦截 AV 系统的服务端控制点，直接禁用控制服务
%hook CCUIControlsServer

- (BOOL)isAVControlsFeatureEnabled {
    return NO;
}

- (id)init {
    return nil; // 直接拒绝初始化服务端对象
}

%end

// 3.【控制器熔断】：拦截所有音视频控制器的基类（从祖先类直接切断）
%hook AVControlsBaseViewController

- (void)viewDidLoad {
    // 不调用 %orig，直接不让它加载任何子视图
    self.view = [[UIView alloc] initWithFrame:CGRectZero];
    self.view.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
}

%end

// 4.【数据伪造】：强制让 SensorKit 广播“没有音频/视频流在运行”
%hook CCUIStatusSensorActivityData

- (BOOL)isSensorActivityActive {
    return NO;
}

%end

// 5.【顶层窗口剔除】：如果系统强行生成了顶级 View，在加入 Window 时直接抹杀
%hook UIView

- (void)didAddSubview:(UIView *)subview {
    %orig;
    NSString *className = NSStringFromClass([subview class]);
    if ([className containsString:@"AVControls"] || 
        [className containsString:@"ControlsServer"] ||
        [className containsString:@"MicMode"]) {
        subview.hidden = YES;
        [subview removeFromSuperview];
    }
}

%end
