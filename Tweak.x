#import <UIKit/UIKit.h>

@interface CCUIHeaderPocketView : UIView
@end

%hook CCUIHeaderPocketView

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

%end