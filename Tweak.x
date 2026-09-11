#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static NSString * const kLogPath =
    @"/var/mobile/Documents/HideAVProbe.log";

static void HVLog(NSString *format, ...)
{
    @autoreleasepool {
        va_list args;
        va_start(args, format);

        NSString *message =
            [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        NSString *line =
            [NSString stringWithFormat:@"%@ [HideAVProbe] %@\n",
             [NSDate date],
             message];

        NSFileHandle *file =
            [NSFileHandle fileHandleForWritingAtPath:kLogPath];

        if (!file) {
            [[NSFileManager defaultManager]
                createFileAtPath:kLogPath
                contents:nil
                attributes:nil];

            file =
                [NSFileHandle fileHandleForWritingAtPath:kLogPath];
        }

        if (file) {
            [file seekToEndOfFile];
            [file writeData:
                [line dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
    }
}

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

        NSString *name =
            NSStringFromClass([module class]);

        return [name isEqualToString:
                    @"RPCCAudioSettingsModule"] ||
               [name isEqualToString:
                    @"RPCCVideoSettingsModule"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}

static BOOL IsHiddenReplayKitModuleIdentifier(id identifier)
{
    if (![identifier isKindOfClass:[NSString class]]) {
        return NO;
    }

    NSString *value = (NSString *)identifier;

    return [value isEqualToString:
                @"com.apple.replaykit.VideoConferenceControlCenterModule"];
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
                SEL moduleSel =
                    sel_registerName("module");

                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        moduleSel
                    );

                NSString *name =
                    module ?
                    NSStringFromClass([module class]) :
                    @"<nil>";

                if ([name isEqualToString:
                         @"RPCCAudioSettingsModule"]) {
                    audioCount++;
                }

                if ([name isEqualToString:
                         @"RPCCVideoSettingsModule"]) {
                    videoCount++;
                }

                HVLog(
                    @"RPCC FILTER -> instance=%p | module=%@ | module=%p",
                    instance,
                    name,
                    module
                );
            }
            @catch (NSException *exception) {
                HVLog(
                    @"RPCC FILTER EXCEPTION -> %@",
                    exception.reason
                );
            }

            continue;
        }

        [filtered addObject:instance];
    }

    HVLog(
        @"FILTER -> original=%lu | audio=%lu | video=%lu | returned=%lu",
        (unsigned long)original.count,
        (unsigned long)audioCount,
        (unsigned long)videoCount,
        (unsigned long)filtered.count
    );

    return filtered;
}

#pragma mark - Module Collection Controller

%hook CCUIModuleCollectionViewController

- (id)initWithModuleInstanceManager:(id)manager
{
    id result = %orig;

    HVLog(
        @"INIT -> CollectionVC=%p | manager=%p",
        result,
        manager
    );

    return result;
}

- (void)moduleInstancesChangedForModuleInstanceManager:(id)manager
{
    HVLog(
        @"EVENT moduleInstancesChanged -> manager=%p",
        manager
    );

    %orig;

    HVLog(
        @"EVENT moduleInstancesChanged -> AFTER %p",
        self
    );
}

- (void)_setupAndAddModuleViewControllerToHierarchy:(id)controller
{
    HVLog(
        @"SETUP/ADD -> controller=%@ | controller=%p",
        controller ?
            NSStringFromClass([controller class]) :
            @"<nil>",
        controller
    );

    id identifier = nil;

    @try {
        SEL identifierSel =
            sel_registerName("moduleIdentifier");

        if ([controller respondsToSelector:identifierSel]) {
            identifier =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    identifierSel
                );
        }
    }
    @catch (NSException *exception) {
        HVLog(
            @"IDENTIFIER EXCEPTION -> %@",
            exception.reason
        );
    }

    if (!identifier) {
        @try {
            SEL identifierSel =
                sel_registerName("identifier");

            if ([controller respondsToSelector:identifierSel]) {
                identifier =
                    ((id (*)(id, SEL))objc_msgSend)(
                        controller,
                        identifierSel
                    );
            }
        }
        @catch (NSException *exception) {
            HVLog(
                @"IDENTIFIER FALLBACK EXCEPTION -> %@",
                exception.reason
            );
        }
    }

    HVLog(
        @"SETUP/ADD -> identifier=%@",
        identifier
    );

    if (IsHiddenReplayKitModuleIdentifier(identifier)) {

        HVLog(
            @"BLOCK VIDEO -> %@ | controller=%p",
            identifier,
            controller
        );

        HVLog(
            @"BLOCK VIDEO -> %orig NOT CALLED"
        );

        return;
    }

    %orig;

    HVLog(
        @"SETUP/ADD -> %orig FINISHED | identifier=%@",
        identifier
    );
}

- (id)moduleViewForIdentifier:(id)identifier
{
    if (IsHiddenReplayKitModuleIdentifier(identifier)) {
        HVLog(
            @"moduleViewForIdentifier -> VIDEO identifier=%@",
            identifier
        );
    }

    id result = %orig;

    if (IsHiddenReplayKitModuleIdentifier(identifier)) {
        HVLog(
            @"moduleViewForIdentifier -> VIDEO result=%p",
            result
        );
    }

    return result;
}

%end

#pragma mark - Module Instance Manager

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *original = %orig;

    if ([original isKindOfClass:[NSArray class]]) {

        NSUInteger audio = 0;
        NSUInteger video = 0;

        for (id instance in original) {

            @try {
                SEL moduleSel =
                    sel_registerName("module");

                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        moduleSel
                    );

                NSString *name =
                    module ?
                    NSStringFromClass([module class]) :
                    @"";

                if ([name isEqualToString:
                         @"RPCCAudioSettingsModule"]) {
                    audio++;
                }

                if ([name isEqualToString:
                         @"RPCCVideoSettingsModule"]) {
                    video++;
                }
            }
            @catch (NSException *exception) {
            }
        }

        HVLog(
            @"moduleInstances -> count=%lu | Audio=%@ | Video=%@",
            (unsigned long)original.count,
            audio ? @"YES" : @"NO",
            video ? @"YES" : @"NO"
        );
    }

    return FilterRPCCModules(original);
}

- (NSArray *)enabledModuleInstances
{
    NSArray *original = %orig;

    if ([original isKindOfClass:[NSArray class]]) {

        NSUInteger audio = 0;
        NSUInteger video = 0;

        for (id instance in original) {

            @try {
                SEL moduleSel =
                    sel_registerName("module");

                id module =
                    ((id (*)(id, SEL))objc_msgSend)(
                        instance,
                        moduleSel
                    );

                NSString *name =
                    module ?
                    NSStringFromClass([module class]) :
                    @"";

                if ([name isEqualToString:
                         @"RPCCAudioSettingsModule"]) {
                    audio++;
                }

                if ([name isEqualToString:
                         @"RPCCVideoSettingsModule"]) {
                    video++;
                }
            }
            @catch (NSException *exception) {
            }
        }

        HVLog(
            @"enabledModuleInstances -> count=%lu | Audio=%@ | Video=%@",
            (unsigned long)original.count,
            audio ? @"YES" : @"NO",
            video ? @"YES" : @"NO"
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

        HVLog(
            @"prototypeModuleSize -> RPCC ZERO | instance=%p",
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

#pragma mark - Constructor

__attribute__((constructor))
static void HideAVProbeInit(void)
{
    @autoreleasepool {

        HVLog(
            @"========== HideAVProbe START =========="
        );

        HVLog(
            @"Log file -> %@",
            kLogPath
        );

        NSString *version =
            [[UIDevice currentDevice] systemVersion];

        HVLog(
            @"Device -> %@",
            version
        );

        HVLog(
            @"Probe target -> _setupAndAddModuleViewControllerToHierarchy:"
        );

        HVLog(
            @"Mode -> BLOCK ONLY VideoConferenceControlCenterModule"
        );

        HVLog(
            @"Hooks installed"
        );

        HVLog(
            @"========== READY =========="
        );
    }
}