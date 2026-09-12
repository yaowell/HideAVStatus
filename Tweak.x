#import <UIKit/UIKit.h>

@interface CCUISensorAttributionCompactControl : UIView
@end

%hook CCUISensorAttributionCompactControl

- (void)didMoveToWindow {
    %orig;
    self.hidden = YES;
    self.userInteractionEnabled = NO;
}

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    self.userInteractionEnabled = NO;
}

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

- (void)setUserInteractionEnabled:(BOOL)enabled {
    %orig(NO);
}

%end