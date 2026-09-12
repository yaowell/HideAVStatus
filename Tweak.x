#import <UIKit/UIKit.h>
#import <objc/runtime.h>

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

@interface CCUISensorAttributionCompactControl : UIView
@end

static void HAPDumpState(UIView *view, NSString *event)
{
    @autoreleasepool {
        UIView *superview = view.superview;

        HAPLog(
            @"[Sensor] %@ | obj=%p | hidden=%@ | alpha=%.2f | frame=%@ | super=%@",
            event,
            view,
            view.hidden ? @"YES" : @"NO",
            view.alpha,
            NSStringFromCGRect(view.frame),
            superview ? NSStringFromClass([superview class]) : @"<nil>"
        );
    }
}

%hook CCUISensorAttributionCompactControl

- (id)initWithFrame:(CGRect)frame {
    id obj = %orig;

    if (obj) {
        HAPLog(
            @"[Sensor] INIT | obj=%p | frame=%@",
            obj,
            NSStringFromCGRect(frame)
        );
    }

    return obj;
}

- (void)didMoveToSuperview {
    %orig;

    HAPDumpState(self, @"didMoveToSuperview");
}

- (void)didMoveToWindow {
    %orig;

    HAPDumpState(self, @"didMoveToWindow");
}

- (void)removeFromSuperview {
    HAPDumpState(self, @"removeFromSuperview BEFORE");

    %orig;

    HAPDumpState(self, @"removeFromSuperview AFTER");
}

- (void)setFrame:(CGRect)frame {
    HAPLog(
        @"[Sensor] setFrame | obj=%p | old=%@ | new=%@",
        self,
        NSStringFromCGRect(self.frame),
        NSStringFromCGRect(frame)
    );

    %orig;
}

- (void)setHidden:(BOOL)hidden {
    HAPLog(
        @"[Sensor] setHidden | obj=%p | old=%@ | new=%@",
        self,
        self.hidden ? @"YES" : @"NO",
        hidden ? @"YES" : @"NO"
    );

    %orig;
}

- (void)setAlpha:(CGFloat)alpha {
    HAPLog(
        @"[Sensor] setAlpha | obj=%p | old=%.2f | new=%.2f",
        self,
        self.alpha,
        alpha
    );

    %orig;
}

%end