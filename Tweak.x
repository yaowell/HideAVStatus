#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>


#pragma mark - ReplayKit Module Filter

static BOOL IsRPCCModule(id instance) {
    if (!instance)
        return NO;

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
        );

        if (!module)
            return NO;

        NSString *name = NSStringFromClass([module class]);

        return [name isEqualToString:@"RPCCAudioSettingsModule"] ||
               [name isEqualToString:@"RPCCVideoSettingsModule"] ||
               [name isEqualToString:@"RPVideoEffectsModule"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}


static NSArray *FilterRPCCModules(NSArray *modules) {
    if (!modules || modules.count == 0)
        return modules;

    NSMutableArray *result =
        [NSMutableArray arrayWithCapacity:modules.count];

    for (id instance in modules) {
        if (!IsRPCCModule(instance)) {
            [result addObject:instance];
        }
    }

    return result;
}


#pragma mark - CCUIModuleInstanceManager

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *result = %orig;
    return FilterRPCCModules(result);
}

- (NSArray *)enabledModuleInstances {
    NSArray *result = %orig;
    return FilterRPCCModules(result);
}

%end


#pragma mark - CCUIModuleInstance

%hook CCUIModuleInstance

- (CGSize)prototypeModuleSize {
    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            self,
            sel_registerName("module")
        );

        if (module) {
            NSString *name =
                NSStringFromClass([module class]);

            if ([name isEqualToString:@"RPCCAudioSettingsModule"] ||
                [name isEqualToString:@"RPCCVideoSettingsModule"] ||
                [name isEqualToString:@"RPVideoEffectsModule"]) {

                return CGSizeZero;
            }
        }
    }
    @catch (NSException *exception) {
    }

    return %orig;
}

%end


#pragma mark - Sensor Attribution Compact Control

@interface CCUISensorAttributionCompactControl : UIView
@end


%hook CCUISensorAttributionCompactControl

- (void)didMoveToWindow {
    %orig;

    /*
     * 只隐藏视觉显示。
     * 保留 userInteractionEnabled，
     * 不改变 frame / size / layout。
     */
    self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;

    /*
     * 系统可能在 layout 时重新设置 hidden，
     * 因此这里继续保持隐藏。
     */
    self.hidden = YES;
}

- (void)setHidden:(BOOL)hidden {
    /*
     * 无论系统要求显示还是隐藏，
     * 最终都保持隐藏。
     */
    %orig(YES);
}

%end


#pragma mark - CCUIHeaderPocketView

%hook CCUIHeaderPocketView

- (void)handleCompactControlExpansionEvent {
    /*
     * 关键处理：
     *
     * 原始流程：
     * handleCompactControlTouchBeganEvent
     *      ↓
     * willOpenExpandedSensorAttributionViewController
     *      ↓
     * handleCompactControlExpansionEvent
     *      ↓
     * 展开二级菜单
     *
     * 这里不调用 %orig，
     * 从而阻止 Sensor Attribution 二级菜单展开。
     *
     * 不修改：
     * Header frame
     * Sensor frame
     * userInteractionEnabled
     * CCUIStatusBar
     * Control Center dismiss
     */
    return;
}

%end