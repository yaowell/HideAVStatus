#import <UIKit/UIKit.h>

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView

- (void)didMoveToWindow {
    %orig;

    self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;

    self.hidden = YES;
}

%end