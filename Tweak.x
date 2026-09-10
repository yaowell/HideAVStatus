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

static BOOL BMIsReplayKitIdentifier(NSString *identifier)
{
    if (!identifier) return NO;

    return
        [identifier containsString:@"RPCCAudio"] ||
        [identifier containsString:@"RPCCVideo"] ||
        [identifier containsString:@"AudioConference"] ||
        [identifier containsString:@"VideoConference"];
}

@class CCUIModuleInstanceManager;
@class CCUIControlCenterPositionProvider;
@class CCUIModularControlCenterOverlayViewController;
@class CCUIModuleCollectionViewController;

%hook CCUIModuleCollectionViewController

- (CGSize)layoutSizeForModuleIdentifier:(NSString *)identifier
                         forOrientation:(long long)orientation
{
    CGSize result =
        %orig(identifier, orientation);

    if (BMIsReplayKitIdentifier(identifier)) {

        BMLog([NSString stringWithFormat:
               @"[SIZE] CCUIModuleCollectionViewController | %@ | orientation=%lld | size=(%.2f, %.2f)",
               identifier,
               orientation,
               (double)result.width,
               (double)result.height]);
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

    if (BMIsReplayKitIdentifier(identifier)) {

        BMLog([NSString stringWithFormat:
               @"[RECT] CCUIControlCenterPositionProvider | %@ | rect=(%.2f, %.2f, %.2f, %.2f)",
               identifier,
               (double)result.origin.x,
               (double)result.origin.y,
               (double)result.size.width,
               (double)result.size.height]);
    }

    return result;
}

- (CGSize)layoutSize
{
    CGSize result = %orig;

    BMLog([NSString stringWithFormat:
           @"[TOTAL SIZE] CCUIControlCenterPositionProvider | size=(%.2f, %.2f)",
           (double)result.width,
           (double)result.height]);

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
           (double)result.width,
           (double)result.height]);

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
           (double)result.width,
           (double)result.height]);

    return result;
}

- (void)requestModuleLayoutSizeUpdateForContentModuleContext:(id)context
{
    BMLog(@"[REQUEST SIZE UPDATE] CCUIModuleInstanceManager");

    %orig(context);
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