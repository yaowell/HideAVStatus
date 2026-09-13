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
 *
 * Hide:
 *   RPCCAudioSettingsModule
 *   RPCCVideoSettingsModule
 *   RPVideoEffectsModule
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
 *
 * Make the RPCC modules occupy zero size.
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
 * New test:
 *
 * DO NOT use hidden = YES.
 *
 * Keep the view in the layout hierarchy so its original
 * height/space remains intact.
 *
 * Make it completely transparent and disable its own
 * interaction so it should not open the secondary menu.
 * ============================================================
 */

@interface CCUISensorAttributionCompactControl : UIView
@end

%hook CCUISensorAttributionCompactControl

- (void)didMoveToWindow {

    %orig;

    self.hidden = NO;
    self.alpha = 0.0;
    self.userInteractionEnabled = NO;
}

- (void)layoutSubviews {

    %orig;

    self.hidden = NO;
    self.alpha = 0.0;
    self.userInteractionEnabled = NO;
}

%end