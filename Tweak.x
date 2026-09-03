#import <UIKit/UIKit.h>

// 1.【源头屏蔽 1】：阻断传感器状态存储中心的数据输出
// 让控制中心查询 activeSensors 时永远返回空，彻底认为当前无麦克风/相机占用
%hook CCUISensorAttributionStore

- (id)activeSensorAttributionData {
    return nil;
}

- (NSArray *)sensorAttributions {
    return @[];
}

- (BOOL)hasActiveSensorAttribution {
    return NO;
}

%end

// 2.【源头屏蔽 2】：拦截状态栏管理器的传感器数据更新
%hook CCUIStatusLabelViewController

- (void)setSensorAttributionData:(id)data {
    // 强制不接受传感器属性更新
    %orig(nil);
}

%end

// 3.【源头屏蔽 3】：拦截 Dynamic Engine 的状态判断
%hook CCUIHeaderPocketView

- (BOOL)isSensorAttributionActive {
    return NO;
}

- (BOOL)isSensorAttributionExpanded {
    return NO;
}

- (void)setSensorAttributionExpanded:(BOOL)expanded {
    %orig(NO);
}

%end
