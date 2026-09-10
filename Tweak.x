#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/CC_Classes.log";

static void WriteLog(NSString *text)
{
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

static void ScanClasses(void)
{
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);

    if (!classes) {
        WriteLog(@"[ERROR] objc_copyClassList returned NULL");
        return;
    }

    NSMutableArray *matches = [NSMutableArray array];

    for (unsigned int i = 0; i < count; i++) {
        Class cls = classes[i];

        if (!cls) continue;

        const char *name = class_getName(cls);

        if (!name) continue;

        NSString *className =
            [NSString stringWithUTF8String:name];

        if ([className containsString:@"RPCCAudio"] ||
            [className containsString:@"RPCCVideo"] ||
            [className containsString:@"ReplayKit"] ||
            [className containsString:@"CCUI"]) {

            [matches addObject:className];
        }
    }

    free(classes);

    [matches sortUsingSelector:@selector(compare:)];

    WriteLog(@"==============================================");
    WriteLog(@"[Runtime Class Scan]");
    WriteLog([NSString stringWithFormat:
              @"Total registered classes: %u", count]);
    WriteLog([NSString stringWithFormat:
              @"Matched classes: %lu",
              (unsigned long)matches.count]);
    WriteLog(@"==============================================");

    for (NSString *name in matches) {
        WriteLog([NSString stringWithFormat:
                  @"[Class] %@", name]);
    }

    WriteLog(@"==============================================");
    WriteLog(@"[Scan Finished]");
    WriteLog(@"==============================================");
}

%ctor
{
    @autoreleasepool {
        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:@"com.apple.springboard"]) {
            return;
        }

        ScanClasses();
    }
}