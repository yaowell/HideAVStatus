#import <UIKit/UIKit.h>

// 1. 显式声明私有类，提供完整的继承结构（解决 forward declaration 报错）
@interface CCUIOverlayStatusBarViewController : UIViewController
- (id)controlsView;
@end

@interface CCUIModuleCollectionView : UIView
@end

// 2. Hook 控制中心状态栏（隐藏音视频状态指示）
%hook CCUIOverlayStatusBarViewController

- (void)viewDidLoad {
    %orig;
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        controlsView.hidden = YES;
        controlsView.alpha = 0.0;
    }
}

%end

// 3. Hook 模块列表视图（过滤视频效果/麦克风模式控件）
%hook CCUIModuleCollectionView

- (void)layoutSubviews {
    %orig;
    for (UIView *subview in self.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        if ([className containsString:@"AVControls"] || 
            [className containsString:@"VideoEffects"] || 
            [className containsString:@"MicMode"]) {
            subview.hidden = YES;
            subview.frame = CGRectZero;
        }
    }
}

%end
