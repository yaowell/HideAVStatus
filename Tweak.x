#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

static NSString *const kLogPath =
@"/var/mobile/Documents/CC_AudioHeight.log";

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

%hook RPCCAudioSettingsModuleBackgroundViewController

- (double)CCUIMenuModuleViewHeight
{
    double height = %orig;

    WriteLog([NSString stringWithFormat:
              @"[Audio Height] %.4f",
              height]);

    return height;
}

%end

%ctor
{
    @autoreleasepool {
        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        if (![bundleID isEqualToString:
              @"com.apple.springboard"]) {
            return;
        }

        WriteLog(@"==============================================");
        WriteLog(@"[Audio Height Probe]");
        WriteLog(@"Hook: CCUIMenuModuleViewHeight");
        WriteLog(@"Mode: Original value only");
        WriteLog(@"==============================================");
    }
}