#import <UIKit/UIKit.h>

@interface CCUILayoutOptions : NSObject
@end

%hook CCUIModuleCollectionViewController

// 1. 过滤掉 topmost (音视频状态) 模块，避免分配顶部坐标
- (id)topmostModuleIdentifier {
    return nil;
}

// 2. 拦截协议中的边距计算：强制将顶部 Margin/Inset 清零
- (UIEdgeInsets)compactLayoutMargins {
    UIEdgeInsets insets = %orig;
    insets.top = 0;
    return insets;
}

- (UIEdgeInsets)expandedLayoutMargins {
    UIEdgeInsets insets = %orig;
    insets.top = 0;
    return insets;
}

// 3. 拦截特定布局计算：清除顶部 Topmost 模块占用的 Frame 高度
- (CGRect)layoutView:(id)layoutView frameForSubview:(UIView *)subview {
    CGRect rect = %orig;
    NSString *cls = NSStringFromClass([subview class]);
    
    // 如果是音视频相关模块，坐标直接清零
    if ([cls containsString:@"AudioConference"] || 
        [cls containsString:@"VideoConference"] || 
        [cls containsString:@"Sensor"] ||
        [cls containsString:@"ReplayKit"]) {
        subview.hidden = YES;
        return CGRectZero;
    }
    
    return rect;
}

%end
