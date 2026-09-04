#import <UIKit/UIKit.h>

@interface CCUIRecordingIndicatorModuleViewController : UIViewController
@end

// 1. Hook 顶部指示器 View，强制隐藏并禁止重绘
%hook CCUIRecordingIndicatorView

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

- (void)setAlpha:(CGFloat)alpha {
    %orig(0.0);
}

- (void)layoutSubviews {
    %orig;
    ((UIView *)self).hidden = YES;
}

%end

// 2. Hook 模块控制器，把展开和常规高度全部归零，消除占位
%hook CCUIRecordingIndicatorModuleViewController

- (double)preferredExpandedContentHeight {
    return 0.0;
}

// 补充常规（未展开状态）的高度归零，彻底防止网格留白
- (double)preferredContentHeight {
    return 0.0;
}

- (CGSize)preferredContentSize {
    return CGSizeZero;
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (self.view) {
        self.view.hidden = YES;
        self.view.frame = CGRectZero;
    }
}

%end
