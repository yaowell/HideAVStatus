#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;


/*
 * ============================================================
 * RPCC module detection
 * ============================================================
 */

static BOOL IsRPCCModule(id instance) {
    if (!instance) {
        return NO;
    }

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
        );

        if (!module) {
            return NO;
        }

        NSString *name = NSStringFromClass([module class]);

        return [name isEqualToString:@"RPCCAudioSettingsModule"] ||
               [name isEqualToString:@"RPCCVideoSettingsModule"] ||
               [name isEqualToString:@"RPVideoEffectsModule"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}


/*
 * ============================================================
 * Filter RPCC modules
 * ============================================================
 */

static NSArray *FilterRPCCModules(NSArray *original) {
    if (![original isKindOfClass:[NSArray class]]) {
        return original;
    }

    NSMutableArray *filtered =
        [NSMutableArray arrayWithCapacity:original.count];

    for (id instance in original) {

        if (IsRPCCModule(instance)) {
            continue;
        }

        [filtered addObject:instance];
    }

    return filtered;
}


/*
 * ============================================================
 * CCUIModuleInstanceManager
 * ============================================================
 */

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *original = %orig;
    return FilterRPCCModules(original);
}

- (NSArray *)enabledModuleInstances {
    NSArray *original = %orig;
    return FilterRPCCModules(original);
}

%end


/*
 * ============================================================
 * CCUIModuleInstance
 * ============================================================
 */

%hook CCUIModuleInstance

- (CCUILayoutSize)prototypeModuleSize {

    if (IsRPCCModule(self)) {

        CCUILayoutSize zeroSize;
        zeroSize.width = 0;
        zeroSize.height = 0;

        return zeroSize;
    }

    return %orig;
}

%end


/*
 * ============================================================
 * CCUISensorAttributionCompactControl
 *
 * 保持上一版已经验证过的隐藏方式：
 *
 * hidden = YES
 * userInteractionEnabled = NO
 *
 * 不使用 alpha
 * 不使用 pointInside
 *
 * 这次只额外处理触摸传递。
 * ============================================================
 */

@interface CCUISensorAttributionCompactControl : UIView
@end

%hook CCUISensorAttributionCompactControl

- (void)didMoveToWindow {

    %orig;

    self.hidden = YES;
    self.userInteractionEnabled = NO;
}

- (void)layoutSubviews {

    %orig;

    self.hidden = YES;
    self.userInteractionEnabled = NO;
}


/*
 * 防止系统重新把控件显示出来。
 */
- (void)setHidden:(BOOL)hidden {

    %orig(YES);
}


/*
 * 保持控件自身不接收触摸。
 *
 * 注意：
 * 这里不再 override pointInside:
 * 因为上一版测试已经证明 pointInside:NO
 * 仍然会出现二级菜单。
 */
- (void)setUserInteractionEnabled:(BOOL)enabled {

    %orig(NO);
}

%end