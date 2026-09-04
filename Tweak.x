#import <UIKit/UIKit.h>

@interface CCUIContentModuleContainerView : UIView
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;
@end

%hook CCUIModuleCollectionView

- (void)layoutSubviews {
    %orig;

    // 记录顶部 Privacy 模块占据的总高度偏移量
    CGFloat topOffsetToReduce = 0.0;

    for (UIView *subview in self.subviews) {
        NSString *className = NSStringFromClass([subview class]);
        
        // 判断是否为 Module Container
        if ([className containsString:@"CCUIContentModuleContainerView"]) {
            CCUIContentModuleContainerView *container = (CCUIContentModuleContainerView *)subview;
            NSString *moduleID = container.moduleIdentifier;

            // 识别麦克风/视频效果模块
            if ([moduleID containsString:@"AudioConferenceCenter"] || 
                [moduleID containsString:@"VideoConferenceCenter"] ||
                [moduleID containsString:@"ReplayKit"]) {
                
                // 隐藏并清空高度
                container.hidden = YES;
                CGRect frame = container.frame;
                if (frame.size.height > 0) {
                    topOffsetToReduce = MAX(topOffsetToReduce, CGRectGetMaxY(frame));
                    frame.size.height = 0;
                    container.frame = frame;
                }
            } else {
                // 下方的正常图标，整体向上平移填补空白
                if (topOffsetToReduce > 0) {
                    CGRect frame = container.frame;
                    frame.origin.y -= topOffsetToReduce;
                    container.frame = frame;
                }
            }
        }
    }
}

%end
