#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

// 1.【iOS 16.2 核心】：直接拦截传感器状态服务，强行返回“无活跃传感器”
%hook CCUIOverlayStatusServer

- (BOOL)isSensorActivityActive {
    return NO;
}

- (id)activeSensorActivityData {
    return nil;
}

%end

// 2.【iOS 16.2 控制中心 Header 绝杀】：阻止 Header 进行传感器拉伸
%hook CCUIHeaderPocketView

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO); // 强制不拉伸
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (void)layoutSubviews {
    %orig;
    // 强行把顶部 Pocket 视图高度锁死为 0
    CGRect frame = self.frame;
    if (frame.size.height > 0) {
        frame.size.height = 0;
        self.frame = frame;
    }
}

%end

// 3.【物理消除音视频模块】：隐藏 View 并强行归零尺寸
%hook RPCCAudioSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

%end

%hook RPCCVideoSettingsModuleViewController

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}

%end

// 4.【容器层压扁】：不给 GridEngine 任何计算空间
%hook CCUIContentModuleContainerViewController

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
