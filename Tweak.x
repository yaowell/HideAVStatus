#import <UIKit/UIKit.h>

@interface CCUISensorAttributionCompactControl : UIView
@end

%hook CCUISensorAttributionCompactControl

- (void)didMoveToWindow {
    %orig;
    self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}

%end