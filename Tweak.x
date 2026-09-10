#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogFilePath = @"/var/mobile/Documents/CC_Probe.log";

static NSMutableSet *gRecordedEntries = nil;
static dispatch_queue_t gLogQueue = nil;

static void BMLog(NSString *message)
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        gRecordedEntries = [NSMutableSet set];
        gLogQueue = dispatch_queue_create("com.yaowell.hideavcontrols.probe", DISPATCH_QUEUE_SERIAL);

        [[NSFileManager defaultManager] removeItemAtPath:kLogFilePath error:nil];
    });

    if (!message) {
        return;
    }

    dispatch_async(gLogQueue, ^{
        if ([gRecordedEntries containsObject:message]) {
            return;
        }

        [gRecordedEntries addObject:message];

        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:kLogFilePath]) {
            [fm createFileAtPath:kLogFilePath contents:nil attributes:nil];
        }

        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:kLogFilePath];

        if (!handle) {
            return;
        }

        [handle seekToEndOfFile];

        NSString *line =
            [NSString stringWithFormat:@"%@\n", message];

        [handle writeData:
            [line dataUsingEncoding:NSUTF8StringEncoding]];

        [handle closeFile];
    });
}

static BOOL BMClassMatches(NSString *name)
{
    if (!name) {
        return NO;
    }

    if ([name hasPrefix:@"CCUI"]) {
        return YES;
    }

    NSArray *keywords = @[
        @"Module",
        @"Layout",
        @"Grid",
        @"Collection",
        @"Content"
    ];

    for (NSString *keyword in keywords) {
        if ([name containsString:keyword] &&
            [name containsString:@"CC"]) {
            return YES;
        }
    }

    return NO;
}

static BOOL BMSelectorMatches(NSString *name)
{
    if (!name) {
        return NO;
    }

    NSString *lower =
        [name lowercaseString];

    NSArray *keywords = @[
        @"layout",
        @"layoutsubviews",
        @"size",
        @"frame",
        @"height",
        @"width",
        @"content",
        @"module",
        @"margin",
        @"padding",
        @"inset",
        @"constraint"
    ];

    for (NSString *keyword in keywords) {
        if ([lower containsString:keyword]) {
            return YES;
        }
    }

    return NO;
}

static void BMScanRuntime(void)
{
    int classCount =
        objc_getClassList(NULL, 0);

    if (classCount <= 0) {
        return;
    }

    Class *classes =
        (Class *)malloc(sizeof(Class) * classCount);

    if (!classes) {
        return;
    }

    classCount =
        objc_getClassList(classes, classCount);

    BMLog([NSString stringWithFormat:
           @"[Scan] Loaded classes: %d",
           classCount]);

    for (int i = 0; i < classCount; i++) {

        Class cls = classes[i];

        if (!cls) {
            continue;
        }

        NSString *className =
            NSStringFromClass(cls);

        if (!BMClassMatches(className)) {
            continue;
        }

        unsigned int methodCount = 0;

        Method *methods =
            class_copyMethodList(cls, &methodCount);

        if (!methods) {
            continue;
        }

        NSMutableArray *selectors =
            [NSMutableArray array];

        for (unsigned int j = 0;
             j < methodCount;
             j++) {

            SEL sel =
                method_getName(methods[j]);

            if (!sel) {
                continue;
            }

            NSString *selectorName =
                NSStringFromSelector(sel);

            if (BMSelectorMatches(selectorName)) {

                if (![selectors containsObject:selectorName]) {
                    [selectors addObject:selectorName];
                }
            }
        }

        free(methods);

        if (selectors.count == 0) {
            continue;
        }

        [selectors
            sortUsingSelector:@selector(compare:)];

        BMLog([NSString stringWithFormat:
               @"[Class] %@ | Methods: %@",
               className,
               [selectors
                   componentsJoinedByString:@", "]]);
    }

    free(classes);
}

static void BMStartProbe(void)
{
    BMLog(@"");
    BMLog(@"==============================================");
    BMLog(@"[Probe] Runtime-only probe started");
    BMLog(@"[Probe] No Logos hooks are active");
    BMLog(@"[Probe] No plist modifications");
    BMLog(@"[Probe] No Control Center modifications");
    BMLog(@"==============================================");

    __block int scanNumber = 0;

    dispatch_queue_t mainQueue =
        dispatch_get_main_queue();

    dispatch_async(mainQueue, ^{

        NSTimer *timer =
            [NSTimer scheduledTimerWithTimeInterval:2.0
                                             repeats:YES
                                               block:^(NSTimer *t) {

            scanNumber++;

            BMLog([NSString stringWithFormat:
                   @"[Scan #%d] Runtime scan",
                   scanNumber]);

            dispatch_async(
                dispatch_get_global_queue(
                    QOS_CLASS_UTILITY,
                    0
                ),
                ^{
                    BMScanRuntime();
                }
            );

            if (scanNumber >= 15) {
                [t invalidate];

                BMLog(@"");
                BMLog(@"==============================================");
                BMLog(@"[Probe] 30 second scan finished");
                BMLog(@"==============================================");
            }
        }];

        [[NSRunLoop mainRunLoop]
            addTimer:timer
            forMode:NSRunLoopCommonModes];
    });
}

%ctor
{
    @autoreleasepool {

        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:
              @"com.apple.springboard"]) {
            return;
        }

        BMLog(@"");
        BMLog(@"==============================================");
        BMLog(@"[Probe] HideAVControls Runtime Probe Loaded");
        BMLog(@"[Probe] SpringBoard detected");
        BMLog(@"==============================================");

        BMStartProbe();
    }
}