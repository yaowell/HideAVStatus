#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <stdarg.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static NSString * const kHideAVProbeLog =
    @"/var/mobile/Documents/HideAVProbe.log";

static void HAPLog(NSString *format, ...)
{
    @autoreleasepool {
        va_list args;
        va_start(args, format);

        NSString *message =
            [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        NSString *line =
            [NSString stringWithFormat:@"%@\n", message];

        @synchronized (kHideAVProbeLog) {
            NSFileManager *fm = [NSFileManager defaultManager];

            NSString *directory =
                [kHideAVProbeLog stringByDeletingLastPathComponent];

            if (![fm fileExistsAtPath:directory]) {
                [fm createDirectoryAtPath:directory
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:nil];
            }

            if (![fm fileExistsAtPath:kHideAVProbeLog]) {
                [line writeToFile:kHideAVProbeLog
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:nil];
            } else {
                NSFileHandle *handle =
                    [NSFileHandle fileHandleForWritingAtPath:kHideAVProbeLog];

                if (handle) {
                    [handle seekToEndOfFile];

                    NSData *data =
                        [line dataUsingEncoding:NSUTF8StringEncoding];

                    [handle writeData:data];
                    [handle closeFile];
                }
            }
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

static NSString *HAPClassName(id object)
{
    if (!object) {
        return @"<nil>";
    }

    return NSStringFromClass([object class]);
}

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances
{
    NSArray *original = %orig;

    BOOL audio = NO;
    BOOL video = NO;

    for (id instance in original) {
        @try {
            SEL moduleSel = sel_registerName("module");

            if (![instance respondsToSelector:moduleSel]) {
                continue;
            }

            id module =
                ((id (*)(id, SEL))objc_msgSend)(
                    instance,
                    moduleSel
                );

            NSString *name =
                module ? NSStringFromClass([module class]) : @"";

            if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                audio = YES;
            }

            if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                video = YES;
            }
        }
        @catch (NSException *exception) {
        }
    }

    HAPLog(@"moduleInstances -> count=%lu | Audio=%@ | Video=%@",
           (unsigned long)original.count,
           audio ? @"YES" : @"NO",
           video ? @"YES" : @"NO");

    NSArray *filtered = FilterRPCCModules(original);

    HAPLog(@"moduleInstances -> returned=%lu",
           (unsigned long)filtered.count);

    return filtered;
}

- (NSArray *)enabledModuleInstances
{
    NSArray *original = %orig;

    BOOL audio = NO;
    BOOL video = NO;

    for (id instance in original) {
        @try {
            SEL moduleSel = sel_registerName("module");

            if (![instance respondsToSelector:moduleSel]) {
                continue;
            }

            id module =
                ((id (*)(id, SEL))objc_msgSend)(
                    instance,
                    moduleSel
                );

            NSString *name =
                module ? NSStringFromClass([module class]) : @"";

            if ([name isEqualToString:@"RPCCAudioSettingsModule"]) {
                audio = YES;
            }

            if ([name isEqualToString:@"RPCCVideoSettingsModule"]) {
                video = YES;
            }
        }
        @catch (NSException *exception) {
        }
    }

    HAPLog(@"enabledModuleInstances -> count=%lu | Audio=%@ | Video=%@",
           (unsigned long)original.count,
           audio ? @"YES" : @"NO",
           video ? @"YES" : @"NO");

    NSArray *filtered = FilterRPCCModules(original);

    HAPLog(@"enabledModuleInstances -> returned=%lu",
           (unsigned long)filtered.count);

    return filtered;
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
    /*
     * 纯探针：
     * 允许系统原始方法完整执行。
     * 不隐藏、不删除、不修改、不阻断。
     */
    %orig;

    @autoreleasepool {
        @try {
            NSString *identifier = @"<unknown>";

            SEL identifierSel =
                sel_registerName("moduleIdentifier");

            if (controller &&
                [controller respondsToSelector:identifierSel]) {

                id value =
                    ((id (*)(id, SEL))objc_msgSend)(
                        controller,
                        identifierSel
                    );

                if ([value isKindOfClass:[NSString class]]) {
                    identifier = value;
                }
            }

            BOOL isVideo =
                [identifier isEqualToString:
                    @"com.apple.replaykit.VideoConferenceControlCenterModule"];

            BOOL isAudio =
                [identifier isEqualToString:
                    @"com.apple.replaykit.AudioConferenceControlCenterModule"];

            if (!isVideo && !isAudio) {
                return;
            }

            UIView *view = nil;

            SEL viewSel = @selector(view);

            if (controller &&
                [controller respondsToSelector:viewSel]) {

                view =
                    ((id (*)(id, SEL))objc_msgSend)(
                        controller,
                        viewSel
                    );
            }

            UIView *superview =
                view ? view.superview : nil;

            UIViewController *parent = nil;

            if ([controller isKindOfClass:
                [UIViewController class]]) {

                parent =
                    ((UIViewController *)controller)
                    .parentViewController;
            }

            HAPLog(@"==============================");
            HAPLog(@"RPCC DYNAMIC SETUP");

            HAPLog(@"controller class = %@",
                   HAPClassName(controller));

            HAPLog(@"controller ptr   = %p",
                   controller);

            HAPLog(@"identifier       = %@",
                   identifier);

            HAPLog(@"view class       = %@",
                   HAPClassName(view));

            HAPLog(@"view ptr         = %p",
                   view);

            HAPLog(@"view frame       = %@",
                   view
                   ? NSStringFromCGRect(view.frame)
                   : @"<nil>");

            HAPLog(@"view hidden      = %@",
                   view
                   ? (view.hidden ? @"YES" : @"NO")
                   : @"<nil>");

            HAPLog(@"view alpha       = %.3f",
                   view ? view.alpha : -1.0);

            HAPLog(@"superview class  = %@",
                   HAPClassName(superview));

            HAPLog(@"superview ptr    = %p",
                   superview);

            HAPLog(@"superview frame  = %@",
                   superview
                   ? NSStringFromCGRect(superview.frame)
                   : @"<nil>");

            HAPLog(@"parent class     = %@",
                   HAPClassName(parent));

            HAPLog(@"parent ptr       = %p",
                   parent);

            if (view) {
                NSArray *subviews = view.subviews;

                HAPLog(@"view subviews    = %lu",
                       (unsigned long)subviews.count);

                NSUInteger index = 0;

                for (UIView *subview in subviews) {
                    HAPLog(
                        @"  subview[%lu] = %@ | ptr=%p | frame=%@ | hidden=%@ | alpha=%.3f",
                        (unsigned long)index,
                        HAPClassName(subview),
                        subview,
                        NSStringFromCGRect(subview.frame),
                        subview.hidden ? @"YES" : @"NO",
                        subview.alpha
                    );

                    index++;
                }
            }

            HAPLog(@"==============================");
        }
        @catch (NSException *exception) {
            HAPLog(@"RPCC PROBE EXCEPTION = %@",
                   exception);
        }
    }
}

%end