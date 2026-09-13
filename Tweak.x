#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - Logger

static void ProbeLog(NSString *format, ...) {
    @autoreleasepool {

        NSString *path =
            @"/var/mobile/Documents/HideAVSensorProbe.log";

        va_list args;
        va_start(args, format);

        NSString *message =
            [[NSString alloc] initWithFormat:format arguments:args];

        va_end(args);

        NSString *line =
            [NSString stringWithFormat:@"%@\n", message];

        NSFileManager *fm =
            [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:path]) {
            [fm createFileAtPath:path
                        contents:nil
                      attributes:nil];
        }

        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:path];

        if (!handle) {
            return;
        }

        @try {
            [handle seekToEndOfFile];

            NSData *data =
                [line dataUsingEncoding:NSUTF8StringEncoding];

            [handle writeData:data];

            [handle closeFile];
        }
        @catch (NSException *exception) {
            @try {
                [handle closeFile];
            }
            @catch (...) {
            }
        }
    }
}


#pragma mark - Safe Helpers

static NSString *ClassName(id obj) {
    if (!obj) {
        return @"<nil>";
    }

    return NSStringFromClass([obj class]);
}


static NSString *FrameString(UIView *view) {

    if (!view) {
        return @"<nil>";
    }

    CGRect f = view.frame;

    return [NSString stringWithFormat:
            @"{{%.1f, %.1f}, {%.1f, %.1f}}",
            f.origin.x,
            f.origin.y,
            f.size.width,
            f.size.height];
}


#pragma mark - Dump Header Subviews

static void DumpHeaderSubviews(UIView *header) {

    if (!header) {
        return;
    }

    ProbeLog(@"");
    ProbeLog(@"========== HEADER SUBVIEWS ==========");

    NSArray *subviews = header.subviews;

    ProbeLog(
        @"[HEADER] class=%@ count=%lu frame=%@",
        ClassName(header),
        (unsigned long)subviews.count,
        FrameString(header)
    );

    NSUInteger index = 0;

    for (UIView *view in subviews) {

        ProbeLog(
            @"[HEADER-SUBVIEW] index=%lu class=%@ frame=%@ hidden=%d alpha=%.2f interaction=%d",
            (unsigned long)index,
            ClassName(view),
            FrameString(view),
            view.hidden,
            view.alpha,
            view.userInteractionEnabled
        );

        index++;
    }

    ProbeLog(@"========== END HEADER SUBVIEWS ==========");
}


#pragma mark - Method Name Scanner

static void DumpInterestingMethods(Class cls) {

    if (!cls) {
        return;
    }

    ProbeLog(@"");
    ProbeLog(@"========== METHODS %@ ==========",
             NSStringFromClass(cls));

    unsigned int count = 0;

    Method *methods =
        class_copyMethodList(cls, &count);

    if (!methods) {
        ProbeLog(@"[METHODS] no methods");
        return;
    }

    for (unsigned int i = 0; i < count; i++) {

        SEL selector =
            method_getName(methods[i]);

        if (!selector) {
            continue;
        }

        NSString *name =
            NSStringFromSelector(selector);

        NSString *lower =
            [name lowercaseString];

        BOOL interesting =
            [lower containsString:@"sensor"] ||
            [lower containsString:@"attribution"] ||
            [lower containsString:@"compact"] ||
            [lower containsString:@"expand"] ||
            [lower containsString:@"header"] ||
            [lower containsString:@"pocket"] ||
            [lower containsString:@"camera"] ||
            [lower containsString:@"microphone"];

        if (interesting) {

            ProbeLog(
                @"[METHOD] %@",
                name
            );
        }
    }

    free(methods);

    ProbeLog(@"========== END METHODS ==========");
}


#pragma mark - Sensor Control

@interface CCUISensorAttributionCompactControl : UIView
@end


%hook CCUISensorAttributionCompactControl


- (instancetype)initWithFrame:(CGRect)frame {

    ProbeLog(
        @"[SENSOR-CREATE] initWithFrame self=%p frame=%@",
        self,
        FrameString((UIView *)self)
    );

    id result = %orig;

    ProbeLog(
        @"[SENSOR-CREATE] result=%p class=%@ frame=%@",
        result,
        ClassName(result),
        FrameString((UIView *)result)
    );

    return result;
}


- (void)didMoveToWindow {

    %orig;

    ProbeLog(
        @"[SENSOR-WINDOW] self=%p window=%@ super=%@ frame=%@",
        self,
        ClassName(self.window),
        ClassName(self.superview),
        FrameString(self)
    );

    if (self.superview) {
        DumpHeaderSubviews(self.superview);
    }
}


- (void)layoutSubviews {

    %orig;

    if (self.superview) {
        DumpHeaderSubviews(self.superview);
    }
}

%end


#pragma mark - Header Pocket

@interface CCUIHeaderPocketView : UIView
@end


%hook CCUIHeaderPocketView


- (instancetype)initWithFrame:(CGRect)frame {

    ProbeLog(
        @"[HEADER-CREATE] initWithFrame frame=%@",
        FrameString((UIView *)self)
    );

    id result = %orig;

    ProbeLog(
        @"[HEADER-CREATE] result=%p class=%@ frame=%@",
        result,
        ClassName(result),
        FrameString((UIView *)result)
    );

    /*
     * 只扫描一次方法。
     */
    static BOOL didDumpMethods = NO;

    if (!didDumpMethods) {

        didDumpMethods = YES;

        DumpInterestingMethods(
            [result class]
        );
    }

    return result;
}


- (void)didMoveToWindow {

    %orig;

    ProbeLog(
        @"[HEADER-WINDOW] self=%p window=%@ frame=%@",
        self,
        ClassName(self.window),
        FrameString(self)
    );

    DumpHeaderSubviews(self);
}


- (void)layoutSubviews {

    CGRect before =
        self.frame;

    %orig;

    CGRect after =
        self.frame;

    ProbeLog(
        @"[HEADER-LAYOUT] self=%p before=%@ after=%@ subviews=%lu",
        self,
        FrameString((UIView *)self),
        FrameString((UIView *)self),
        (unsigned long)self.subviews.count
    );

    if (!CGRectEqualToRect(before, after)) {

        ProbeLog(
            @"[HEADER-LAYOUT-CHANGE] header frame changed"
        );
    }

    DumpHeaderSubviews(self);
}


- (void)addSubview:(UIView *)view {

    ProbeLog(
        @"[HEADER-ADD-SUBVIEW] header=%p adding class=%@ frame=%@",
        self,
        ClassName(view),
        FrameString(view)
    );

    %orig;
}


- (void)insertSubview:(UIView *)view
              atIndex:(NSInteger)index {

    ProbeLog(
        @"[HEADER-INSERT] header=%p class=%@ index=%ld",
        self,
        ClassName(view),
        (long)index
    );

    %orig;
}


- (void)willRemoveSubview:(UIView *)subview {

    ProbeLog(
        @"[HEADER-REMOVE] header=%p removing class=%@",
        self,
        ClassName(subview)
    );

    %orig;
}

%end


#pragma mark - Constructor

%ctor {

    ProbeLog(@"");
    ProbeLog(@"========================================");
    ProbeLog(@"HideAVSensorProbe v2 START");
    ProbeLog(@"========================================");
}