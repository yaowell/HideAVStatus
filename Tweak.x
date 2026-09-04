#import <UIKit/UIKit.h>

@interface CCUILayoutView : UIView
@end

%hook CCUILayoutView

- (CGRect)frameForSubview:(UIView *)subview {
    CGRect originalFrame = %orig;
    NSString *cls = NSStringFromClass([subview class]);
    
    // 1. 如果是顶部的传感器/音视频模块，直接将坐标和尺寸清零
    if ([cls containsString:@"AudioConference"] || 
        [cls containsString:@"VideoConference"] || 
        [cls containsString:@"Sensor"] ||
        [cls containsString:@"ReplayKit"]) {
        subview.hidden = YES;
        return CGRectZero;
    }
    
    // 2. 如果顶部的模块被隐藏，将下方所有正常图标整体向上平移偏移量（通常为顶部卡片高度 + 间距）
    // 提示：若平移高度需要微调，可根据实际效果调整 70 这个数值
    if (originalFrame.origin.y > 0) {
        originalFrame.origin.y = MAX(0, originalFrame.origin.y - 70);
    }
    
    return originalFrame;
}

%end
