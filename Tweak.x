#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 彻底干掉 VC 视图
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
%end

// 2.【核心】重写 CollectionView Layout，从布局计算层直接剔除卡片并重新排列 Y 轴
%hook UICollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray<UICollectionViewLayoutAttributes *> *attributes = %orig(rect);
    if (!attributes) return nil;

    NSMutableArray *newAttributes = [NSMutableArray array];
    CGFloat offsetYToReduce = 0.0;

    for (UICollectionViewLayoutAttributes *attr in attributes) {
        // 判断当前 LayoutAttributes 是否属于音视频卡片
        UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:attr.indexPath];
        BOOL isAVModule = NO;

        if (cell) {
            UIResponder *responder = cell;
            while (responder) {
                if ([responder isKindOfClass:[UIViewController class]]) {
                    NSString *cls = NSStringFromClass([responder class]);
                    if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
                        isAVModule = YES;
                        break;
                    }
                }
                responder = [responder nextResponder];
            }
        }

        if (isAVModule) {
            // 记录被隐藏模块占用的高度，后续所有图标统一上移该高度
            if (offsetYToReduce == 0.0) {
                offsetYToReduce = attr.frame.size.height + 10.0; // 包含模块间距
            }
            continue; // 直接从布局数组里扔掉这两个卡片
        }

        // 如果已经触发了偏移，将后续所有图标的 Frame Y 轴向上移动
        if (offsetYToReduce > 0.0) {
            UICollectionViewLayoutAttributes *copyAttr = [attr copy];
            CGRect f = copyAttr.frame;
            f.origin.y -= offsetYToReduce;
            copyAttr.frame = f;
            [newAttributes addObject:copyAttr];
        } else {
            [newAttributes addObject:attr];
        }
    }

    return newAttributes;
}

%end
