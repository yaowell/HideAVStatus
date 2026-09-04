#import <UIKit/UIKit.h>

@interface CCUILayoutView : UIView
@end

%hook CCUILayoutView

// 1. 从排版列表中彻底过滤掉麦克风/视频效果 View，让它完全不参与坐标分配
- (NSArray *)subviewsToLayout {
    NSArray *originalSubviews = %orig;
    NSMutableArray *filtered = [NSMutableArray array];
    
    for (UIView *subview in originalSubviews) {
        NSString *cls = NSStringFromClass([subview class]);
        if ([cls containsString:@"AudioConference"] || 
            [cls containsString:@"VideoConference"] || 
            [cls containsString:@"Sensor"] ||
            [cls containsString:@"ReplayKit"]) {
            subview.hidden = YES; // 顺手隐藏
            continue; // 跳过，不计入排版队列
        }
        [filtered addObject:subview];
    }
    return [filtered copy];
}

// 2. 将垂直双倍行距置空，消除顶部的额外 Margin/Padding 占位
- (id)_verticalDoubleMarginIndices {
    return nil;
}

%end
