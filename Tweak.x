#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static __weak id gModuleCollectionViewController = nil;

static BOOL IsRPCCModule(id instance)
{
    if (!instance) return NO;

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
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

    if (result) {
        gModuleCollectionViewController = result;
    }

    return result;
}

- (void)moduleInstancesChangedForModuleInstanceManager:(id)manager
{
    %orig;

    if (@available(iOS 17.0, *)) {

        id obj = self;

        SEL selector =
            sel_registerName("_updateModuleControllers");

        if ([obj respondsToSelector:selector]) {

            ((void (*)(id, SEL))objc_msgSend)(
                obj,
                selector
            );
        }
    }
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