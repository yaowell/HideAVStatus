#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static void CHLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message =
        [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSLog(@"[HideAVProbe] %@", message);
}

static BOOL IsRPCCModule(id instance)
{
    if (!instance) return NO;

    @try {
        SEL moduleSelector =
            sel_registerName("module");

        if (![instance respondsToSelector:moduleSelector]) {
            return NO;
        }

        id module =
            ((id (*)(id, SEL))objc_msgSend)(
                instance,
                moduleSelector
            );

        if (!module) return NO;

        NSString *name =
            NSStringFromClass([module class]);

        BOOL isRPCC =
            [name isEqualToString:@"RPCCAudioSettingsModule"] ||
            [name isEqualToString:@"RPCCVideoSettingsModule"];

        if (isRPCC) {
            CHLog(
                @"RPCC INSTANCE -> %@ | instance=%p | module=%@ | module=%p",
                NSStringFromClass([instance class]),
                instance,
                name,
                module
            );
        }

        return isRPCC;
    }
    @catch (NSException *exception) {
        CHLog(
            @"IsRPCCModule exception -> %@",
            exception.reason
        );
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

    NSUInteger audioCount = 0;
    NSUInteger videoCount = 0;

    for (id instance in original) {

        if (IsRPCCModule(instance)) {

            @try {
                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        sel_registerName("module")
                    );

                NSString *name =
                    module ?
                    NSStringFromClass([module class]) :
                    @"<nil>";

                if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                    audioCount++;
                }

                if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                    videoCount++;
                }
            }
            @catch (NSException *exception) {
            }

            continue;
        }

        [filtered addObject:instance];
    }

    if (audioCount || videoCount) {
        CHLog(
            @"FILTER -> original=%lu | audio=%lu | video=%lu | returned=%lu",
            (unsigned long)original.count,
            (unsigned long)audioCount,
            (unsigned long)videoCount,
            (unsigned long)filtered.count
        );
    }

    return filtered;
}

#pragma mark - Module Instance Manager Probe

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *original = %orig;

    BOOL hasAudio = NO;
    BOOL hasVideo = NO;

    if ([original isKindOfClass:[NSArray class]]) {

        for (id instance in original) {

            @try {
                SEL moduleSelector =
                    sel_registerName("module");

                if (![instance respondsToSelector:moduleSelector]) {
                    continue;
                }

                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        moduleSelector
                    );

                if (!module) {
                    continue;
                }

                NSString *name =
                    NSStringFromClass([module class]);

                if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                    hasAudio = YES;
                }

                if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                    hasVideo = YES;
                }
            }
            @catch (NSException *exception) {
            }
        }
    }

    if (hasAudio || hasVideo) {

        CHLog(
            @"moduleInstances -> count=%lu | Audio=%@ | Video=%@",
            (unsigned long)original.count,
            hasAudio ? @"YES" : @"NO",
            hasVideo ? @"YES" : @"NO"
        );
    }

    return FilterRPCCModules(original);
}

- (NSArray *)enabledModuleInstances
{
    NSArray *original = %orig;

    BOOL hasAudio = NO;
    BOOL hasVideo = NO;

    if ([original isKindOfClass:[NSArray class]]) {

        for (id instance in original) {

            @try {
                SEL moduleSelector =
                    sel_registerName("module");

                if (![instance respondsToSelector:moduleSelector]) {
                    continue;
                }

                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        moduleSelector
                    );

                if (!module) {
                    continue;
                }

                NSString *name =
                    NSStringFromClass([module class]);

                if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                    hasAudio = YES;
                }

                if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                    hasVideo = YES;
                }
            }
            @catch (NSException *exception) {
            }
        }
    }

    if (hasAudio || hasVideo) {

        CHLog(
            @"enabledModuleInstances -> count=%lu | Audio=%@ | Video=%@",
            (unsigned long)original.count,
            hasAudio ? @"YES" : @"NO",
            hasVideo ? @"YES" : @"NO"
        );
    }

    return FilterRPCCModules(original);
}

%end

#pragma mark - Module Instance

%hook CCUIModuleInstance

- (CCUILayoutSize)prototypeModuleSize
{
    if (IsRPCCModule(self)) {

        CHLog(
            @"prototypeModuleSize -> HIDDEN | instance=%p",
            self
        );

        CCUILayoutSize zeroSize;
        zeroSize.width = 0;
        zeroSize.height = 0;

        return zeroSize;
    }

    return %orig;
}

%end