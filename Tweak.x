#import <UIKit/UIKit.h>

@interface NSNotificationCenter (CCUIBlock)
@end

// 1.【绝杀广播信号】：拦截所有发给控制中心的传感器状态变化通知
%hook NSNotificationCenter

- (void)postNotificationName:(NSNotificationName)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    NSString *name = (NSString *)aName;
    if ([name containsString:@"SensorAttribution"] || 
        [name containsString:@"AVSystemController_SystemVolume"] ||
        [name containsString:@"PrivacyAccounting"] ||
        [name containsString:@"RPCCAudio"] ||
        [name containsString:@"RPCCVideo"]) {
        // 强行丢弃通知，不向 ControlCenter 广播
        return;
    }
    %orig;
}

%end

// 2.【绝杀视图层状态】：锁死 Pocket 视图，不允许响应任何展开状态
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

- (void)setSensorAttributionExpanded:(BOOL)expanded animated:(BOOL)animated {
    %orig(NO, NO);
}

%end
