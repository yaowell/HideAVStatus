#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static BOOL IsRPCCModule(id instance)
{
    if (!instance) {
        return NO;
    }

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

        if (!module) {
            return NO;
        }

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

%hook CCUIModuleCollectionViewController

- (void)_setupAndAddModuleViewControllerToHierarchy:(id)controller
{
    %orig;

    @try {
        if (!controller) {
            return;
        }

        SEL identifierSel =
            sel_registerName("moduleIdentifier");

        if (![controller respondsToSelector:identifierSel]) {
            return;
        }

        NSString *identifier =
            ((id (*)(id, SEL))objc_msgSend)(
                controller,
                identifierSel
            );

        if (![identifier isKindOfClass:[NSString class]]) {
            return;
        }

        if (![identifier isEqualToString:
              @"com.apple.replaykit.VideoConferenceControlCenterModule"]) {
            return;
        }

        UIView *view = nil;

        SEL viewSel = @selector(view);

        if ([controller respondsToSelector:viewSel]) {
            view =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    viewSel
                );
        }

        if (view) {
            view.hidden = YES;
        }
    }
    @catch (NSException *exception) {
    }
}

%end