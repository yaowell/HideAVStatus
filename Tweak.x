#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static BOOL IsRPCCModule(id instance) {
    if (!instance) return NO;

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
        );

        if (!module) return NO;

        NSString *name = NSStringFromClass([module class]);

        return [name isEqualToString:@"RPCCAudioSettingsModule"] ||
               [name isEqualToString:@"RPCCVideoSettingsModule"] ||
               [name isEqualToString:@"RPVideoEffectsModule"];
    } @catch (NSException *exception) {
        return NO;
    }
}

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

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

- (void)setUserInteractionEnabled:(BOOL)enabled {
    %orig(NO);
}

%end