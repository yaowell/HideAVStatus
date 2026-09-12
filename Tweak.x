#import <UIKit/UIKit.h>

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

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView

- (void)layoutSubviews {
    %orig;

    @autoreleasepool {
        NSArray *subviews = self.subviews;

        HAPLog(@"==============================");
        HAPLog(@"CCUIHeaderPocketView subviews=%lu",
               (unsigned long)subviews.count);

        for (NSUInteger i = 0; i < subviews.count; i++) {
            UIView *view = subviews[i];

            HAPLog(@"[%lu] class=%@ | frame=%@ | hidden=%@ | alpha=%.2f",
                   (unsigned long)i,
                   NSStringFromClass([view class]),
                   NSStringFromCGRect(view.frame),
                   view.hidden ? @"YES" : @"NO",
                   view.alpha);
        }

        HAPLog(@"==============================");
    }
}

%end