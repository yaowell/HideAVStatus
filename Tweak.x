#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1.【绝杀 Sensor 状态源头】抹掉所有麦克风/相机活跃属性
// 没有 activeSensor，系统完全不会去加载音视频卡片，面板高度直接保持默认！
%hook CCUISensorAttributionStore

- (id)activeSensorAttributionData {
    return nil;
}

- (NSArray *)sensorAttributions {
    return @[];
}

%end

// 2.【绝杀状态栏/Header 展开逻辑】强制 HeaderPocket 永远处于非 Sensor 激活状态
%hook CCUIHeaderPocketView

- (BOOL)isSensorAttributionCompact {
    return YES;
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

%end

// 3.【模块降级掩护】如果强行加载，直接归零
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end
