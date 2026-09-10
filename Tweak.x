#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogFilePath = @"/var/mobile/Documents/CC_Probe.log";

static NSMutableSet *gRecordedEntries;
static dispatch_queue_t gLogQueue;

static void BMLog(NSString *msg)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gRecordedEntries = [NSMutableSet set];
        gLogQueue = dispatch_queue_create("com.yaowell.ccprobe.log", DISPATCH_QUEUE_SERIAL);
        [[NSFileManager defaultManager] removeItemAtPath:kLogFilePath error:nil];
    });

    if (!msg) return;

    dispatch_async(gLogQueue, ^{
        if ([gRecordedEntries containsObject:msg]) return;
        [gRecordedEntries addObject:msg];

        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:kLogFilePath]) {
            [fm createFileAtPath:kLogFilePath contents:nil attributes:nil];
        }

        NSFileHandle *h =
            [NSFileHandle fileHandleForWritingAtPath:kLogFilePath];

        if (!h) return;

        [h seekToEndOfFile];

        NSString *line =
            [NSString stringWithFormat:@"%@\n", msg];

        [h writeData:
            [line dataUsingEncoding:NSUTF8StringEncoding]];

        [h closeFile];
    });
}

static NSString *BMClassName(id obj)
{
    if (!obj) return @"nil";
    return NSStringFromClass([obj class]) ?: @"Unknown";
}

static NSString *BMModuleIdentifier(id obj)
{
    if (!obj) return @"Unknown";

    @try {
        id value = [obj valueForKey:@"moduleIdentifier"];
        if (value) return [value description];
    }
    @catch (__unused NSException *e) {}

    @try {
        id value = [obj valueForKey:@"identifier"];
        if (value) return [value description];
    }
    @catch (__unused NSException *e) {}

    return @"Unknown";
}

%hook CCUIModuleCollectionViewController

- (CGSize)layoutSizeForModuleIdentifier:(NSString *)identifier
                         forOrientation:(long long)orientation
{
    CGSize result =
        %orig(identifier, orientation);

    if (identifier &&
        ([identifier containsString:@"RPCCAudio"] ||
         [identifier containsString:@"RPCCVideo"] ||
         [identifier containsString:@"AudioConference"] ||
         [identifier containsString:@"VideoConference"])) {

        BMLog([NSString stringWithFormat:
               @"[SIZE] CCUIModuleCollectionViewController | %@ | orientation=%lld | size=(%.2f, %.2f)",
               identifier,
               orientation,
               result.width,
               result.height]);
    }

    return result;
}

- (void)moduleInstancesLayoutChangedForModuleInstanceManager:(id)manager
{
    BMLog(@"[LAYOUT CHANGE] CCUIModuleCollectionViewController");

    %orig(manager);
}

%end

%hook CCUIControlCenterPositionProvider

- (CGRect)layoutRectForIdentifier:(NSString *)identifier
{
    CGRect result =
        %orig(identifier);

    if (identifier &&
        ([identifier containsString:@"RPCCAudio"] ||
         [identifier containsString:@"RPCCVideo"] ||
         [identifier containsString:@"AudioConference"] ||
         [identifier containsString:@"VideoConference"])) {

        BMLog([NSString stringWithFormat:
               @"[RECT] CCUIControlCenterPositionProvider | %@ | rect=(%.2f, %.2f, %.2f, %.2f)",
               identifier,
               result.origin.x,
               result.origin.y,
               result.size.width,
               result.size.height]);
    }

    return result;
}

- (CGSize)layoutSize
{
    CGSize result = %orig;

    BMLog([NSString stringWithFormat:
           @"[TOTAL SIZE] CCUIControlCenterPositionProvider | size=(%.2f, %.2f)",
           result.width,
           result.height]);

    return result;
}

%end

%hook CCUIModularControlCenterOverlayViewController

- (NSInteger)moduleRowCount
{
    NSInteger result = %orig;

    BMLog([NSString stringWithFormat:
           @"[ROW COUNT] CCUIModularControlCenterOverlayViewController | %ld",
           (long)result]);

    return result;
}

- (CGSize)moduleLayoutSizeForContentModuleContext:(id)context
                                   forOrientation:(long long)orientation
{
    CGSize result =
        %orig(context, orientation);

    BMLog([NSString stringWithFormat:
           @"[MODULE LAYOUT SIZE] CCUIModularControlCenterOverlayViewController | orientation=%lld | size=(%.2f, %.2f)",
           orientation,
           result.width,
           result.height]);

    return result;
}

- (void)moduleInstancesLayoutChangedForModuleInstanceManager:(id)manager
{
    BMLog(@"[OVERLAY LAYOUT CHANGE] CCUIModularControlCenterOverlayViewController");

    %orig(manager);
}

%end

%hook CCUIModuleInstanceManager

- (CGSize)moduleLayoutSizeForContentModuleContext:(id)context
                                   forOrientation:(long long)orientation
{
    CGSize result =
        %orig(context, orientation);

    BMLog([NSString stringWithFormat:
           @"[INSTANCE MANAGER SIZE] orientation=%lld | size=(%.2f, %.2f)",
           orientation,
           result.width,
           result.height]);

    return result;
}

- (void)requestModuleLayoutSizeUpdateForContentModuleContext:(id)context
{
    BMLog(@"[REQUEST SIZE UPDATE] CCUIModuleInstanceManager");

    %orig(context);
}

%end

%hook CCUIContentModuleContainerViewController

- (void)viewWillLayoutSubviews
{
    id module = nil;
    NSString *identifier = @"Unknown";

    @try {
        module = [self valueForKey:@"contentModule"];
        identifier = BMModuleIdentifier(module);
    }
    @catch (__unused NSException *e) {}

    if ([identifier containsString:@"RPCCAudio"] ||
        [identifier containsString:@"RPCCVideo"] ||
        [identifier containsString:@"AudioConference"] ||
        [identifier containsString:@"VideoConference"]) {

        BMLog([NSString stringWithFormat:
               @"[CONTAINER LAYOUT] %@ | module=%@ | frame=(%.2f, %.2f, %.2f, %.2f)",
               identifier,
               BMClassName(module),
               self.view.frame.origin.x,
               self.view.frame.origin.y,
               self.view.frame.size.width,
               self.view.frame.size.height]);
    }

    %orig;
}

%end

%ctor
{
    @autoreleasepool {

        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        BMLog(@"==============================================");
        BMLog(@"[Probe] Precise CC Layout Probe Loaded");
        BMLog(@"[Probe] SpringBoard detected");
        BMLog(@"[Probe] Observation only");
        BMLog(@"[Probe] No plist modification");
        BMLog(@"[Probe] No layout modification");
        BMLog(@"==============================================");
    }
}