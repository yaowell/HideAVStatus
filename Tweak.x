#import <UIKit/UIKit.h>

@interface CCUILayoutView : UIView
@end

%hook CCUILayoutView

// 1. 布局子视图时，把所有 ReplayKit / Audio / Video 模块直接隐藏并移出排版
- (void)layoutSubviews {
    %orig;
    
    for (UIView *subview in self.subviews) {
        NSString *cls = NSStringFromClass([subview class]);
        if ([cls containsString:@"AudioConference"] || 
            [cls containsString:@"VideoConference"] || 
            [cls containsString:@"Sensor"] ||
            [cls containsString:@"ReplayKit"]) {
            subview.hidden = YES;
            // 消除其在自定义 Layout 中占据的实际高度
            subview.frame = CGRectZero;
        }
    }
}

%end
