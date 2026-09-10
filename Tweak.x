#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/CC_RPCC_Classes.log";

static NSMutableSet *gFoundClasses;
static dispatch_source_t gTimer;

static void WriteLog(NSString *text)
{
    if (!text) return;

    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:kLogPath]) {
        [fm createFileAtPath:kLogPath contents:nil attributes:nil];
    }

    NSFileHandle *file =
        [NSFileHandle fileHandleForWritingAtPath:kLogPath];

    if (!file) return;

    [file seekToEndOfFile];

    NSString *line =
        [NSString stringWithFormat:@"%@\n", text];

    [file writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
}

static BOOL IsTargetClass(NSString *name)
{
    if (!name) return NO;

    return
        [name hasPrefix:@"RPCCAudio"] ||
        [name hasPrefix:@"RPCCVideo"];
}

static void ScanRPCCClasses(void)
{
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);

    if (!classes) return;

    for (unsigned int i = 0; i < count; i++) {
        Class cls = classes[i];

        if (!cls) continue;

        const char *cname = class_getName(cls);

        if (!cname) continue;

        NSString *name =
            [NSString stringWithUTF8String:cname];

        if (!IsTargetClass(name)) continue;

        if ([gFoundClasses containsObject:name]) continue;

        [gFoundClasses addObject:name];

        WriteLog([NSString stringWithFormat:
                  @"[NEW CLASS] %@", name]);
    }

    free(classes);
}

static void StartScanner(void)
{
    gFoundClasses = [NSMutableSet set];

    [[NSFileManager defaultManager]
        removeItemAtPath:kLogPath
        error:nil];

    WriteLog(@"==============================================");
    WriteLog(@"[RPCC Runtime Scanner]");
    WriteLog(@"[Interval] 1 second");
    WriteLog(@"[Duration] 60 seconds");
    WriteLog(@"[Target] RPCCAudio / RPCCVideo");
    WriteLog(@"[Mode] Observation only");
    WriteLog(@"[Hook] NONE");
    WriteLog(@"[Plist] NONE");
    WriteLog(@"==============================================");

    ScanRPCCClasses();

    gTimer =
        dispatch_source_create(
            DISPATCH_SOURCE_TYPE_TIMER,
            0,
            0,
            dispatch_get_main_queue());

    if (!gTimer) return;

    dispatch_source_set_timer(
        gTimer,
        dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
        1 * NSEC_PER_SEC,
        100 * NSEC_PER_MSEC);

    dispatch_source_set_event_handler(gTimer, ^{
        static int scanCount = 0;

        scanCount++;

        ScanRPCCClasses();

        if (scanCount >= 60) {
            WriteLog(@"==============================================");
            WriteLog(@"[Scanner Finished]");
            WriteLog([NSString stringWithFormat:
                      @"[RPCC classes found] %lu",
                      (unsigned long)gFoundClasses.count]);
            WriteLog(@"==============================================");

            dispatch_source_cancel(gTimer);
            gTimer = nil;
        }
    });

    dispatch_resume(gTimer);
}

%ctor
{
    @autoreleasepool {
        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        StartScanner();
    }
}