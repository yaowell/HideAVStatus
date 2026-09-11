#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static NSString *CHLogPath(void)
{
    return @"/var/mobile/Documents/HideAVProbe.log";
}

static void CHLog(NSString *format, ...)
{
    va_list args;
    va_start(args, format);

    NSString *message =
        [[NSString alloc] initWithFormat:format arguments:args];

    va_end(args);

    NSString *line =
        [NSString stringWithFormat:@"%@ [HideAVProbe] %@\n",
         [NSDate date],
         message];

    @try {
        NSString *path = CHLogPath();

        NSString *dir =
            [path stringByDeletingLastPathComponent];

        NSFileManager *fm =
            [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:dir]) {
            [fm createDirectoryAtPath:dir
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
        }

        if (![fm fileExistsAtPath:path]) {

            [line writeToFile:path
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil];

        } else {

            NSFileHandle *handle =
                [NSFileHandle fileHandleForWritingAtPath:path];

            if (handle) {

                [handle seekToEndOfFile];

                NSData *data =
                    [line dataUsingEncoding:NSUTF8StringEncoding];

                [handle writeData:data];

                [handle closeFile];
            }
        }
    }
    @catch (NSException *exception) {
    }

    NSLog(@"[HideAVProbe] %@", message);
}

static NSString *CHModuleName(id instance)
{
    if (!instance) {
        return nil;
    }

    @try {
        SEL selector =
            sel_registerName("module");

        if (![instance respondsToSelector:selector]) {
            return nil;
        }

        id module =
            ((id (*)(id, SEL))objc_msgSend)(
                instance,
                selector
            );

        if (!module) {
            return nil;
        }

        return NSStringFromClass([module class]);
    }
    @catch (NSException *exception) {
        return nil;
    }
}

static BOOL IsRPCCModule(id instance)
{
    NSString *name = CHModuleName(instance);

    if (!name) {
        return NO;
    }

    BOOL isAudio =
        [name isEqualToString:@"RPCCAudioSettingsModule"];

    BOOL isVideo =
        [name isEqualToString:@"RPCCVideoSettingsModule"];

    if (isAudio || isVideo) {

        CHLog(
            @"RPCC INSTANCE -> %@ | instance=%p | module=%@",
            NSStringFromClass([instance class]),
            instance,
            name
        );
    }

    return isAudio || isVideo;
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

        NSString *name =
            CHModuleName(instance);

        if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
            audioCount++;
            continue;
        }

        if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
            videoCount++;
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

#pragma mark - Module Instance Manager

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *original = %orig;

    BOOL hasAudio = NO;
    BOOL hasVideo = NO;

    if ([original isKindOfClass:[NSArray class]]) {

        for (id instance in original) {

            NSString *name =
                CHModuleName(instance);

            if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                hasAudio = YES;
            }

            if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                hasVideo = YES;
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

            NSString *name =
                CHModuleName(instance);

            if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                hasAudio = YES;
            }

            if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                hasVideo = YES;
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

#pragma mark - Module Instance Size

%hook CCUIModuleInstance

- (CCUILayoutSize)prototypeModuleSize
{
    if (IsRPCCModule(self)) {

        CHLog(
            @"prototypeModuleSize -> HIDDEN | instance=%p | module=%@",
            self,
            CHModuleName(self)
        );

        CCUILayoutSize zeroSize;
        zeroSize.width = 0;
        zeroSize.height = 0;

        return zeroSize;
    }

    return %orig;
}

%end

#pragma mark - Collection View Controller Probe

%hook CCUIModuleCollectionViewController

- (void)_setupAndAddModuleViewControllerToHierarchy:(id)moduleViewController
{
    id controller = moduleViewController;

    NSString *controllerClass =
        controller ?
        NSStringFromClass([controller class]) :
        @"<nil>";

    CHLog(
        @"SETUP/ADD -> controller=%@ | controller=%p",
        controllerClass,
        controller
    );

    @try {

        id module = nil;

        SEL moduleSelector =
            sel_registerName("module");

        if ([controller respondsToSelector:moduleSelector]) {

            module =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    moduleSelector
                );
        }

        if (module) {

            NSString *moduleClass =
                NSStringFromClass([module class]);

            CHLog(
                @"SETUP/ADD -> module=%@ | module=%p",
                moduleClass,
                module
            );

            if ([moduleClass isEqualToString:@"RPCCAudioSettingsModule"]) {

                CHLog(
                    @"SETUP/ADD -> *** RPCC AUDIO DETECTED ***"
                );
            }

            if ([moduleClass isEqualToString:@"RPCCVideoSettingsModule"]) {

                CHLog(
                    @"SETUP/ADD -> *** RPCC VIDEO DETECTED ***"
                );
            }
        }

        SEL identifierSelector =
            sel_registerName("moduleIdentifier");

        if ([controller respondsToSelector:identifierSelector]) {

            id identifier =
                ((id (*)(id, SEL))objc_msgSend)(
                    controller,
                    identifierSelector
                );

            if (identifier) {

                CHLog(
                    @"SETUP/ADD -> identifier=%@",
                    identifier
                );
            }
        }
    }
    @catch (NSException *exception) {

        CHLog(
            @"SETUP/ADD exception -> %@",
            exception.reason
        );
    }

    %orig;
}

%end

#pragma mark - Init

__attribute__((constructor))
static void CHInit(void)
{
    @autoreleasepool {

        CHLog(
            @"========== HideAVProbe START =========="
        );

        CHLog(
            @"Log file -> %@",
            CHLogPath()
        );

        CHLog(
            @"Device -> %@",
            [[UIDevice currentDevice] systemVersion]
        );

        CHLog(
            @"Hooks installed"
        );

        CHLog(
            @"Probe target -> _setupAndAddModuleViewControllerToHierarchy:"
        );

        CHLog(
            @"========== READY =========="
        );
    }
}