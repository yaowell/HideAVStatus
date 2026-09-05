#import <UIKit/UIKit.h>

// 1. Hook 头部视图（包含麦克风/相机隐私提示的 PocketView）
%hook CCUIHeaderPocketView

- (void)layoutSubviews {
    %orig;
    // 隐藏自身及所有子视图，阻止其占用高度
    self.hidden = YES;
    self.alpha = 0.0;
    
    // 如果有 frame 重置高度为 0
    CGRect frame = self.frame;
    if (frame.size.height > 0) {
        frame.size.height = 0;
        self.frame = frame;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    // 告诉父布局：我的高度是 0
    return CGSizeZero;
}

- (CGFloat)compactHeight {
    return 0.0;
}

- (CGFloat)expandedHeight {
    return 0.0;
}

%end

// 2. Hook 负责整体布局和滚动的 Container，消除顶部的 Padding/Margin
%hook CCUIModuleCollectionView

- (void)setFrame:(CGRect)frame {
    // 强制修正 frame，防止系统根据 Header 留出顶部空白
    %orig;
}

%end

// 3. 拦截模块管理器（防止底层的实例依然保留）
%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *original = %orig;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:original.count];
    for (id instance in original) {
        NSString *identifier = @"";
        @try {
            identifier = [instance valueForKey:@"moduleIdentifier"] ?: @"";
        } @catch (NSException *e) {}
        
        if ([identifier containsString:@"RPCCAudio"] || 
            [identifier containsString:@"RPCCVideo"] ||
            [identifier containsString:@"AudioConferenceCenter"] ||
            [identifier containsString:@"VideoConferenceCenter"] ||
            [identifier containsString:@"Privacy"]) {
            continue;
        }
        [filtered addObject:instance];
    }
    return filtered;
}

%end
