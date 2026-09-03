#import <UIKit/UIKit.h>

// 针对 iOS 15 - 18 控制中心顶部音频/视频控制容器进行 Hook
%hook CCUIOverlayStatusBarViewController

- (void)viewDidLoad {
    %orig;
    // 强制隐藏顶部音频/视频效果控制区域视图
    if ([self respondsToSelector:@selector(controlsView)]) {
        UIView *controlsView = [self performSelector:@selector(controlsView)];
        controlsView.hidden = YES;
        controlsView.alpha = 0.0;
    }
}

%end

// 针对内部模块视图（做双重保障）
%hook CCUIModuleCollectionView

- (void)layoutSubviews {
    %orig;
    for (UIView *subview in self.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        // 匹配麦克风和视频效果的类名关键字
        if ([className containsString:@"AVControls"] || 
            [className containsString:@"VideoEffects"] || 
            [className containsString:@"MicMode"]) {
            subview.hidden = YES;
            subview.frame = CGRectZero;
        }
    }
}

%end
