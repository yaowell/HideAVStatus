#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kLogPath = @"/var/mobile/Documents/HideAVSensorProbe.log";

static void HSPLog(NSString *format, ...) {
    @autoreleasepool {
        va_list args;
        va_start(args, format);

        NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        NSString *line =
            [NSString stringWithFormat:@"%@ %@\n",
             [NSDate date], msg];

        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

        NSFileHandle *fh =
            [NSFileHandle fileHandleForWritingAtPath:kLogPath];

        if (!fh) {
            [[NSFileManager defaultManager]
                createFileAtPath:kLogPath
                contents:nil
                attributes:nil];

            fh =
                [NSFileHandle fileHandleForWritingAtPath:kLogPath];
        }

        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:data];
            [fh closeFile];
        }
    }
}

static NSString *HSPFrame(UIView *view) {
    if (!view)
        return @"<nil>";

    CGRect f = view.frame;

    return [NSString stringWithFormat:
            @"{{%.1f,%.1f},{%.1f,%.1f}}",
            f.origin.x,
            f.origin.y,
            f.size.width,
            f.size.height];
}

static void HSPDumpHeader(id selfObj, NSString *tag) {
    @try {
        UIView *header = (UIView *)selfObj;

        HSPLog(
            @"[%@] HEADER frame=%@ hidden=%d alpha=%.2f interaction=%d subviews=%lu",
            tag,
            HSPFrame(header),
            header.hidden,
            header.alpha,
            header.userInteractionEnabled,
            (unsigned long)header.subviews.count
        );

        for (NSUInteger i = 0;
             i < header.subviews.count;
             i++) {

            UIView *v = header.subviews[i];

            HSPLog(
                @"[%@]   subview[%lu] class=%@ frame=%@ hidden=%d alpha=%.2f interaction=%d",
                tag,
                (unsigned long)i,
                NSStringFromClass([v class]),
                HSPFrame(v),
                v.hidden,
                v.alpha,
                v.userInteractionEnabled
            );
        }
    }
    @catch (NSException *e) {
        HSPLog(
            @"[DUMP-EXCEPTION] %@",
            e.reason ?: @"unknown"
        );
    }
}


%hook CCUIHeaderPocketView


- (void)handleCompactControlTouchBeganEvent {
    HSPLog(
        @"[CALL] handleCompactControlTouchBeganEvent"
    );

    HSPDumpHeader(self, @"TOUCH-BEGIN");

    %orig;

    HSPLog(
        @"[RETURN] handleCompactControlTouchBeganEvent"
    );
}


- (void)handleCompactControlExpansionEvent {
    HSPLog(
        @"[CALL] handleCompactControlExpansionEvent"
    );

    HSPDumpHeader(self, @"EXPANSION-BEFORE");

    %orig;

    HSPDumpHeader(self, @"EXPANSION-AFTER");

    HSPLog(
        @"[RETURN] handleCompactControlExpansionEvent"
    );
}


- (void)handleCompactControlCompactionEvent {
    HSPLog(
        @"[CALL] handleCompactControlCompactionEvent"
    );

    HSPDumpHeader(self, @"COMPACTION-BEFORE");

    %orig;

    HSPDumpHeader(self, @"COMPACTION-AFTER");

    HSPLog(
        @"[RETURN] handleCompactControlCompactionEvent"
    );
}


- (void)willOpenExpandedSensorAttributionViewController {
    HSPLog(
        @"[CALL] willOpenExpandedSensorAttributionViewController"
    );

    HSPDumpHeader(self, @"WILL-OPEN");

    %orig;

    HSPLog(
        @"[RETURN] willOpenExpandedSensorAttributionViewController"
    );
}


- (void)didCloseExpandedSensorAttributionViewController {
    HSPLog(
        @"[CALL] didCloseExpandedSensorAttributionViewController"
    );

    HSPDumpHeader(self, @"DID-CLOSE");

    %orig;

    HSPLog(
        @"[RETURN] didCloseExpandedSensorAttributionViewController"
    );
}


- (BOOL)isSensorAttributionViewControllerExpanded {
    BOOL result = %orig;

    HSPLog(
        @"[CALL] isSensorAttributionViewControllerExpanded -> %d",
        result
    );

    return result;
}


%end


%ctor {
    @autoreleasepool {
        HSPLog(@"");
        HSPLog(@"========== HideAVSensorProbe START ==========");
        HSPLog(@"PID=%d", getpid());
        HSPLog(@"========== Waiting for CCUIHeaderPocketView ==========");
    }
}