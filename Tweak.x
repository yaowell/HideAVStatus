#import <UIKit/UIKit.h>

%hook CCUIModuleCollectionViewController

// 1. 从源头拒绝加载这两个模块的 Controller
- (void)addModuleWithIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"MicMode"] || 
        [identifier containsString:@"CameraVideoEffect"] || 
        [identifier containsString:@"VideoEffect"] ||
        [identifier containsString:@"AVControls"]) {
        return; // 直接拦截
    }
    %orig;
}

// 2. 拦截 View 层，确保无论何时出现直接隐形并清除高度
- (CGRect)layoutView:(id)layoutView frameForSubview:(UIView *)subview {
    CGRect rect = %orig;
    NSString *cls = NSStringFromClass([subview class]);
    
    if ([cls containsString:@"MicMode"] || 
        [cls containsString:@"CameraVideoEffect"] || 
        [cls containsString:@"VideoEffect"] ||
        [cls containsString:@"OverlayHeader"]) {
        subview.hidden = YES;
        return CGRectZero;
    }
    
    return rect;
}

%end
