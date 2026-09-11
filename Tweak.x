#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static BOOL IsRPCCModule(id instance)
{
    if (!instance) return NO;

    @try {
        SEL moduleSel = sel_registerName("module");

        if (![instance respondsToSelector:moduleSel]) {
            return NO;
        }

        id module =
            ((id (*)(id, SEL))objc_msgSend)(
                instance,
                moduleSel
            );

        if (!module) return NO;

        NSString *name = NSStringFromClass([module class]);

        return [name isEqualToString:@"RPCCAudioSettingsModule"] ||
               [name isEqualToString:@"RPCCVideoSettingsModule"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}

static BOOL IsHiddenReplayKitIdentifier(id identifier)
{
    if (![identifier isKindOfClass:[NSString class]]) {
        return NO;
    }

    NSString *value = (NSString *)identifier;

    return [value isEqualToString:@"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
           [value isEqualToString:@"com.apple.replaykit.VideoConferenceControlCenterModule"];
}

static NSArray *FilterRPCCModules(NSArray *original)
{
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

#pragma mark - Module Collection Controller

%hook CCUIModuleCollectionViewController

- (id)initWithModuleInstanceManager:(id)manager
{
    id result = %orig;
    return result;
}

- (void)moduleInstancesChangedForModuleInstanceManager:(id)manager
{
    %orig;

    if (@available(iOS 17.0, *)) {
        id obj = self;

        SEL selector =
            sel_registerName("_updateEnabledModuleIdentifiers");

        if ([obj respondsToSelector:selector]) {
            @try {
                ((void (*)(id, SEL))objc_msgSend)(
                    obj,
                    selector
                );
            }
            @catch (NSException *exception) {
            }
        }

        SEL refreshSelector =
            sel_registerName("_refreshModuleViewControllers");

        if ([obj respondsToSelector:refreshSelector]) {
            @try {
                ((void (*)(id, SEL))objc_msgSend)(
                    obj,
                    refreshSelector
                );
            }
            @catch (NSException *exception) {
            }
        }
    }
}

- (id)moduleViewForIdentifier:(id)identifier
{
    if (IsHiddenReplayKitIdentifier(identifier)) {
        return nil;
    }

    return %orig;
}

%end

#pragma mark - Module Instance Manager

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *original = %orig;

    return FilterRPCCModules(original);
}

- (NSArray *)enabledModuleInstances
{
    NSArray *original = %orig;

    return FilterRPCCModules(original);
}

%end

#pragma mark - Module Instance

%hook CCUIModuleInstance

- (CCUILayoutSize)prototypeModuleSize
{
    if (IsRPCCModule(self)) {
        CCUILayoutSize zeroSize;
        zeroSize.width = 0;
        zeroSize.height = 0;
        return zeroSize;
    }

    return %orig;
}

%end