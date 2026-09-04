#import <UIKit/UIKit.h>

@interface CCUIContentModuleContainerView : UIView
@property (nonatomic, copy, readonly) NSString *moduleIdentifier;
@end

// 1. 阻止 ContainerView 本身被设置尺寸或显示
%hook CCUIContentModuleContainerView

- (void)setFrame:(CGRect)frame {
    if (self.moduleIdentifier && ([self.moduleIdentifier containsString:@"audio"] || 
                                  [self.moduleIdentifier containsString:@"video"] || 
                                  [self.moduleIdentifier containsString:@"Privacy"] ||
                                  [self.moduleIdentifier containsString:@"ReplayKit"])) {
        %orig(CGRectZero);
        self.hidden = YES;
        return;
    }
    %orig;
}

- (void)layoutSubviews {
    if (self.moduleIdentifier && ([self.moduleIdentifier containsString:@"audio"] || 
                                  [self.moduleIdentifier containsString:@"video"] || 
                                  [self.moduleIdentifier containsString:@"Privacy"] ||
                                  [self.moduleIdentifier containsString:@"ReplayKit"])) {
        self.hidden = YES;
        self.frame = CGRectZero;
        return;
    }
    %orig;
}

%end

// 2. 拦截 CollectionView 数据源（彻底不给它生成或计算 Cell 空间）
%hook CCUIModuleCollectionViewController

- (CGSize)collectionView:(id)cv layout:(id)l sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 如果是目标模块直接返回 0 尺寸
    return %orig; 
}

%end
