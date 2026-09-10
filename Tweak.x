#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kLogPath =
@"/var/mobile/Documents/CC_RPCC_Types.log";

static NSArray *TargetClasses(void)
{
    return @[
        @"RPCCVideoSettingsModuleBackgroundViewController",
        @"RPCCAudioSettingsModuleBackgroundViewController",
        @"RPCCVideoSettingsModuleViewController",
        @"RPCCAudioSettingsModuleViewController"
    ];
}

static NSArray *TargetMethods(void)
{
    return @[
        @"CCUIMenuModuleViewHeight",
        @"CCUIMenuModuleViewWidth",
        @"preferredExpandedContentHeight",
        @"layoutVideoConferenceSubviews",
        @"viewWillLayoutSubviews"
    ];
}

static void WriteLog(NSString *text)
{
    if (!text) return;

    NSFileManager *fm = [NSFileManager defaultManager];

    if (![fm fileExistsAtPath:kLogPath]) {
        [fm createFileAtPath:kLogPath
                    contents:nil
                  attributes:nil];
    }

    NSFileHandle *file =
        [NSFileHandle fileHandleForWritingAtPath:kLogPath];

    if (!file) return;

    [file seekToEndOfFile];

    NSString *line =
        [NSString stringWithFormat:@"%@\n", text];

    [file writeData:
        [line dataUsingEncoding:NSUTF8StringEncoding]];

    [file closeFile];
}

static void ScanTypes(void)
{
    WriteLog(@"==============================================");
    WriteLog(@"[RPCC Method Type Scanner]");
    WriteLog(@"==============================================");

    for (NSString *className in TargetClasses()) {

        Class cls = NSClassFromString(className);

        if (!cls) {
            WriteLog([NSString stringWithFormat:
                      @"[NOT FOUND] %@", className]);
            continue;
        }

        WriteLog(@"");
        WriteLog([NSString stringWithFormat:
                  @"[CLASS] %@", className]);

        for (NSString *methodName in TargetMethods()) {

            SEL selector =
                NSSelectorFromString(methodName);

            Method method =
                class_getInstanceMethod(cls, selector);

            if (!method) {
                continue;
            }

            const char *types =
                method_getTypeEncoding(method);

            if (!types) {
                WriteLog([NSString stringWithFormat:
                          @"  %@ | [NO TYPE]",
                          methodName]);
                continue;
            }

            WriteLog([NSString stringWithFormat:
                      @"  %@ | types=%s",
                      methodName,
                      types]);
        }
    }

    WriteLog(@"");
    WriteLog(@"==============================================");
    WriteLog(@"[Scan Finished]");
    WriteLog(@"==============================================");
}

static void StartScanner(void)
{
    [[NSFileManager defaultManager]
        removeItemAtPath:kLogPath
        error:nil];

    WriteLog(@"[Waiting for RPCC classes...]");

    dispatch_source_t timer =
        dispatch_source_create(
            DISPATCH_SOURCE_TYPE_TIMER,
            0,
            0,
            dispatch_get_main_queue());

    if (!timer) return;

    dispatch_source_set_timer(
        timer,
        dispatch_time(DISPATCH_TIME_NOW,
                      1 * NSEC_PER_SEC),
        1 * NSEC_PER_SEC,
        100 * NSEC_PER_MSEC);

    dispatch_source_set_event_handler(timer, ^{
        static int count = 0;

        count++;

        BOOL found = NO;

        for (NSString *className in TargetClasses()) {
            if (NSClassFromString(className)) {
                found = YES;
                break;
            }
        }

        if (found || count >= 60) {
            ScanTypes();
            dispatch_source_cancel(timer);
        }
    });

    dispatch_resume(timer);
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

        StartScanner();
    }
}