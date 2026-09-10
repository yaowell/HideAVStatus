#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/CC_RPCC_Methods.log";

static NSArray *TargetClasses(void)
{
    return @[
        @"RPCCVideoSettingsModule",
        @"RPCCAudioSettingsModule",
        @"RPCCVideoSettingsModuleBackgroundViewController",
        @"RPCCAudioSettingsModuleBackgroundViewController",
        @"RPCCVideoSettingsModuleViewController",
        @"RPCCAudioSettingsModuleViewController"
    ];
}

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

static void ScanMethods(void)
{
    WriteLog(@"==============================================");
    WriteLog(@"[RPCC Method Runtime Scanner]");

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

        unsigned int count = 0;

        Method *methods =
            class_copyMethodList(cls, &count);

        if (!methods) {
            WriteLog(@"[No methods]");
            continue;
        }

        WriteLog([NSString stringWithFormat:
                  @"[Method Count] %u", count]);

        NSMutableArray *names = [NSMutableArray array];

        for (unsigned int i = 0; i < count; i++) {

            Method method = methods[i];

            if (!method) continue;

            SEL selector =
                method_getName(method);

            if (!selector) continue;

            NSString *name =
                NSStringFromSelector(selector);

            if (name) {
                [names addObject:name];
            }
        }

        free(methods);

        [names sortUsingSelector:@selector(compare:)];

        for (NSString *name in names) {
            WriteLog([NSString stringWithFormat:
                      @"  %@", name]);
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
        dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC),
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

            ScanMethods();

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

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        StartScanner();
    }
}