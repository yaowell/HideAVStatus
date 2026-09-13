#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#pragma mark - File Logger

static void SensorProbeLog(NSString *format, ...) {
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

        NSFileManager *fm = [NSFileManager defaultManager];

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


#pragma mark - Safe Description

static NSString *SafeClassName(id obj) {
    if (!obj) {
        return @"<nil>";
    }

    return NSStringFromClass([obj class]);
}


static NSString *SafeFrameString(UIView *view) {
    if (!view) {
        return @"<nil>";
    }

    CGRect frame = view.frame;

    return [NSString stringWithFormat:
            @"{{%.1f, %.1f}, {%.1f, %.1f}}",
            frame.origin.x,
            frame.origin.y,
            frame.size.width,
            frame.size.height];
}


static NSString *SafeBoundsString(UIView *view) {
    if (!view) {
        return @"<nil>";
    }

    CGRect bounds = view.bounds;

    return [NSString stringWithFormat:
            @"{{%.1f, %.1f}, {%.1f, %.1f}}",
            bounds.origin.x,
            bounds.origin.y,
            bounds.size.width,
            bounds.size.height];
}


#pragma mark - View Hierarchy

static void DumpSensorHierarchy(UIView *view) {

    if (!view) {
        SensorProbeLog(@"[Hierarchy] view=nil");
        return;
    }

    SensorProbeLog(@"========== SENSOR HIERARCHY ==========");

    UIView *current = view;
    NSInteger level = 0;

    while (current && level < 12) {

        UIView *superview = current.superview;

        SensorProbeLog(
            @"[Hierarchy] level=%ld class=%@ frame=%@ bounds=%@ hidden=%d alpha=%.2f userInteraction=%d super=%@",
            (long)level,
            SafeClassName(current),
            SafeFrameString(current),
            SafeBoundsString(current),
            current.hidden,
            current.alpha,
            current.userInteractionEnabled,
            SafeClassName(superview)
        );

        current = superview;
        level++;
    }

    SensorProbeLog(@"========== END HIERARCHY ==========");
}


#pragma mark - Sensor Attribution Control

@interface CCUISensorAttributionCompactControl : UIView
@end


%hook CCUISensorAttributionCompactControl


/*
 * ============================================================
 * initWithFrame
 * ============================================================
 */

- (instancetype)initWithFrame:(CGRect)frame {

    SensorProbeLog(
        @"[CREATE] initWithFrame ENTER frame={{%.1f, %.1f}, {%.1f, %.1f}}",
        frame.origin.x,
        frame.origin.y,
        frame.size.width,
        frame.size.height
    );

    id result = %orig;

    SensorProbeLog(
        @"[CREATE] initWithFrame EXIT self=%p class=%@ frame=%@ bounds=%@",
        self,
        SafeClassName(result),
        SafeFrameString(result),
        SafeBoundsString(result)
    );

    return result;
}


/*
 * ============================================================
 * didMoveToWindow
 * ============================================================
 */

- (void)didMoveToWindow {

    %orig;

    SensorProbeLog(
        @"[WINDOW] didMoveToWindow self=%p window=%@ frame=%@ hidden=%d alpha=%.2f",
        self,
        SafeClassName(self.window),
        SafeFrameString(self),
        self.hidden,
        self.alpha
    );

    DumpSensorHierarchy(self);
}


/*
 * ============================================================
 * layoutSubviews
 * ============================================================
 */

- (void)layoutSubviews {

    CGRect beforeFrame = self.frame;
    CGRect beforeBounds = self.bounds;

    %orig;

    SensorProbeLog(
        @"[LAYOUT] self=%p BEFORE frame=%@ bounds=%@",
        self,
        SafeFrameString(self),
        SafeBoundsString(self)
    );

    SensorProbeLog(
        @"[LAYOUT] self=%p AFTER frame=%@ bounds=%@",
        self,
        SafeFrameString(self),
        SafeBoundsString(self)
    );

    if (!CGRectEqualToRect(beforeFrame, self.frame) ||
        !CGRectEqualToRect(beforeBounds, self.bounds)) {

        SensorProbeLog(
            @"[LAYOUT-CHANGE] self=%p changed during layout",
            self
        );
    }
}


/*
 * ============================================================
 * setFrame:
 * ============================================================
 */

- (void)setFrame:(CGRect)frame {

    SensorProbeLog(
        @"[FRAME] self=%p old=%@ new={{%.1f, %.1f}, {%.1f, %.1f}}",
        self,
        SafeFrameString(self),
        frame.origin.x,
        frame.origin.y,
        frame.size.width,
        frame.size.height
    );

    %orig;
}


/*
 * ============================================================
 * setBounds:
 * ============================================================
 */

- (void)setBounds:(CGRect)bounds {

    SensorProbeLog(
        @"[BOUNDS] self=%p old=%@ new={{%.1f, %.1f}, {%.1f, %.1f}}",
        self,
        SafeBoundsString(self),
        bounds.origin.x,
        bounds.origin.y,
        bounds.size.width,
        bounds.size.height
    );

    %orig;
}


/*
 * ============================================================
 * setHidden:
 * ============================================================
 */

- (void)setHidden:(BOOL)hidden {

    SensorProbeLog(
        @"[HIDDEN] self=%p old=%d new=%d",
        self,
        self.hidden,
        hidden
    );

    %orig;
}


/*
 * ============================================================
 * setAlpha:
 * ============================================================
 */

- (void)setAlpha:(CGFloat)alpha {

    SensorProbeLog(
        @"[ALPHA] self=%p old=%.2f new=%.2f",
        self,
        self.alpha,
        alpha
    );

    %orig;
}


/*
 * ============================================================
 * setUserInteractionEnabled:
 * ============================================================
 */

- (void)setUserInteractionEnabled:(BOOL)enabled {

    SensorProbeLog(
        @"[INTERACTION] self=%p old=%d new=%d",
        self,
        self.userInteractionEnabled,
        enabled
    );

    %orig;
}


/*
 * ============================================================
 * touches
 * ============================================================
 */

- (void)touchesBegan:(NSSet *)touches
           withEvent:(UIEvent *)event {

    SensorProbeLog(
        @"[TOUCH] touchesBegan self=%p",
        self
    );

    %orig;
}


- (void)touchesEnded:(NSSet *)touches
           withEvent:(UIEvent *)event {

    SensorProbeLog(
        @"[TOUCH] touchesEnded self=%p",
        self
    );

    %orig;
}

%end


#pragma mark - Constructor

%ctor {

    SensorProbeLog(@"");
    SensorProbeLog(@"========================================");
    SensorProbeLog(@"HideAVSensorProbe START");
    SensorProbeLog(@"========================================");
}