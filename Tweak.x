#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <stdarg.h>
#import <unistd.h>

static NSString * const kProbeLogPath = @"/var/mobile/Documents/HideAVProbe.log";

static void HVLog(NSString *format, ...)
{
    @try {
        va_list args;
        va_start(args, format);

        NSString *message =
            [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        NSString *line =
            [NSString stringWithFormat:@"%@\n", message];

        NSFileHandle *file =
            [NSFileHandle fileHandleForWritingAtPath:kProbeLogPath];

        if (!file) {
            [[NSFileManager defaultManager]
                createFileAtPath:kProbeLogPath
                contents:nil
                attributes:nil];

            file =
                [NSFileHandle fileHandleForWritingAtPath:kProbeLogPath];
        }

        if (file) {
            [file seekToEndOfFile];
            [file writeData:
                [line dataUsingEncoding:NSUTF8StringEncoding]];
            [file closeFile];
        }
    }
    @catch (NSException *exception) {
    }
}

static BOOL HVIsRPCCModule(id instance)
{
    if (!instance) {
        return NO;
    }

    @try {
        SEL moduleSel =
            sel_registerName("module");

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

        return
            [name isEqualToString:@"RPCCAudioSettingsModule"] ||
            [name isEqualToString:@"RPCCVideoSettingsModule"];
    }
    @catch (NSException *exception) {
        return NO;
    }
}

static void HVLogModuleArray(NSArray *array, NSString *tag)
{
    if (![array isKindOfClass:[NSArray class]]) {
        HVLog(@"%@ -> NOT ARRAY", tag);
        return;
    }

    BOOL audio = NO;
    BOOL video = NO;

    for (id instance in array) {
        if (!HVIsRPCCModule(instance)) {
            continue;
        }

        @try {
            SEL moduleSel =
                sel_registerName("module");

            id module =
                ((id (*)(id, SEL))objc_msgSend)(
                    instance,
                    moduleSel
                );

            NSString *name =
                module
                ? NSStringFromClass([module class])
                : @"<nil>";

            if ([name isEqualToString:
                 @"RPCCAudioSettingsModule"]) {
                audio = YES;
            }

            if ([name isEqualToString:
                 @"RPCCVideoSettingsModule"]) {
                video = YES;
            }

            HVLog(
                @"%@ -> instance=%p | module=%@ | module=%p",
                tag,
                instance,
                name,
                module
            );
        }
        @catch (NSException *exception) {
        }
    }

    HVLog(
        @"%@ -> count=%lu | Audio=%@ | Video=%@",
        tag,
        (unsigned long)array.count,
        audio ? @"YES" : @"NO",
        video ? @"YES" : @"NO"
    );
}

%hook CCUIModuleCollectionViewController

- (id)initWithModuleInstanceManager:(id)manager
{
    HVLog(
        @"===== INIT ===== | self=%p | manager=%p",
        self,
        manager
    );

    id result = %orig;

    HVLog(
        @"INIT -> AFTER | self=%p | result=%p",
        self,
        result
    );

    return result;
}

- (void)moduleInstancesChangedForModuleInstanceManager:(id)manager
{
    HVLog(
        @"===== EVENT moduleInstancesChanged ===== | self=%p | manager=%p",
        self,
        manager
    );

    %orig;

    HVLog(
        @"EVENT moduleInstancesChanged -> AFTER | self=%p",
        self
    );
}

- (void)orderedEnabledModuleIdentifiersChangedForSettingsManager:(id)manager
{
    HVLog(
        @"===== EVENT orderedEnabledModuleIdentifiersChanged ===== | self=%p | manager=%p",
        self,
        manager
    );

    %orig;

    HVLog(
        @"orderedEnabledModuleIdentifiersChanged -> AFTER"
    );
}

- (void)moduleInstancesLayoutChangedForModuleInstanceManager:(id)manager
{
    HVLog(
        @"===== EVENT moduleInstancesLayoutChanged ===== | self=%p | manager=%p",
        self,
        manager
    );

    %orig;

    HVLog(
        @"moduleInstancesLayoutChanged -> AFTER"
    );
}

- (void)_updateEnabledModuleIdentifiers
{
    HVLog(
        @"===== CALL _updateEnabledModuleIdentifiers ===== | self=%p",
        self
    );

    %orig;

    HVLog(
        @"_updateEnabledModuleIdentifiers -> AFTER"
    );
}

- (void)_updateModuleControllers
{
    HVLog(
        @"===== CALL _updateModuleControllers ===== | self=%p",
        self
    );

    %orig;

    HVLog(
        @"_updateModuleControllers -> AFTER"
    );
}

- (void)_populateModulesIfNecessary
{
    HVLog(
        @"===== CALL _populateModulesIfNecessary ===== | self=%p",
        self
    );

    %orig;

    HVLog(
        @"_populateModulesIfNecessary -> AFTER"
    );
}

- (void)_populateModuleViewControllers
{
    HVLog(
        @"===== CALL _populateModuleViewControllers ===== | self=%p",
        self
    );

    %orig;

    HVLog(
        @"_populateModuleViewControllers -> AFTER"
    );
}

- (void)_setupAndAddModuleViewControllerToHierarchy:(id)controller
{
    HVLog(
        @"===== CALL _setupAndAdd... ===== | self=%p | controller=%p | class=%@",
        self,
        controller,
        controller
        ? NSStringFromClass([controller class])
        : @"<nil>"
    );

    @try {
        SEL identifierSel =
            sel_registerName("moduleIdentifier");

        if (controller &&
            [controller respondsToSelector:identifierSel]) {

            id identifier =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    identifierSel
                );

            HVLog(
                @"SETUP/ADD -> moduleIdentifier=%@",
                identifier
            );
        } else {
            HVLog(
                @"SETUP/ADD -> moduleIdentifier selector unavailable"
            );
        }
    }
    @catch (NSException *exception) {
        HVLog(
            @"SETUP/ADD -> identifier exception=%@",
            exception
        );
    }

    %orig;

    HVLog(
        @"SETUP/ADD -> FINISHED | controller=%p",
        controller
    );
}

- (void)_removeAndTearDownModuleViewControllerFromHierarchy:(id)controller
{
    HVLog(
        @"===== CALL _removeAndTearDown... ===== | self=%p | controller=%p | class=%@",
        self,
        controller,
        controller
        ? NSStringFromClass([controller class])
        : @"<nil>"
    );

    @try {
        SEL identifierSel =
            sel_registerName("moduleIdentifier");

        if (controller &&
            [controller respondsToSelector:identifierSel]) {

            id identifier =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    identifierSel
                );

            HVLog(
                @"REMOVE -> moduleIdentifier=%@",
                identifier
            );
        } else {
            HVLog(
                @"REMOVE -> moduleIdentifier selector unavailable"
            );
        }
    }
    @catch (NSException *exception) {
        HVLog(
            @"REMOVE -> identifier exception=%@",
            exception
        );
    }

    %orig;

    HVLog(
        @"REMOVE -> FINISHED | controller=%p",
        controller
    );
}

- (id)moduleViewForIdentifier:(id)identifier
{
    if ([identifier isKindOfClass:[NSString class]]) {
        NSString *value = (NSString *)identifier;

        if ([value isEqualToString:
             @"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
            [value isEqualToString:
             @"com.apple.replaykit.VideoConferenceControlCenterModule"]) {

            HVLog(
                @"moduleViewForIdentifier -> REQUEST %@",
                value
            );
        }
    }

    id result = %orig;

    if ([identifier isKindOfClass:[NSString class]]) {
        NSString *value = (NSString *)identifier;

        if ([value isEqualToString:
             @"com.apple.replaykit.AudioConferenceControlCenterModule"] ||
            [value isEqualToString:
             @"com.apple.replaykit.VideoConferenceControlCenterModule"]) {

            HVLog(
                @"moduleViewForIdentifier -> RESULT %@ | result=%p",
                value,
                result
            );
        }
    }

    return result;
}

%end

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *result = %orig;

    HVLogModuleArray(
        result,
        @"moduleInstances"
    );

    return result;
}

- (NSArray *)enabledModuleInstances
{
    NSArray *result = %orig;

    HVLogModuleArray(
        result,
        @"enabledModuleInstances"
    );

    return result;
}

%end

%ctor
{
    HVLog(@"");
    HVLog(@"========================================");
    HVLog(@"HideAVProbe START");
    HVLog(@"PID=%d", getpid());
    HVLog(@"========================================");
}