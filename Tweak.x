#import <UIKit/UIKit.h>

@interface CCUIModuleCollectionViewController : UIViewController <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 保留你已验证有效的 VC 实体剥离
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

// 2.【绝杀 CollectionView 占位】：直接干掉占位 Cell 的尺寸计算
%hook CCUIModuleCollectionViewController

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 获取当前 indexPath 对应的 VC 或 Cell
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    
    // 如果 Cell 内部包含音视频模块，或者 frame 符合截图中的 {159, 72} 动态卡片特征
    if (cell) {
        NSString *cellDescription = [cell description];
        if ([cellDescription containsString:@"RPCCAudio"] || [cellDescription containsString:@"RPCCVideo"]) {
            return CGSizeZero; // 强行把 Cell 尺寸归零，CollectionView 会自动将后续 Cell 上移补位
        }
    }
    
    CGSize originalSize = %orig;
    // 双重保险：防线归零
    if (originalSize.height == 72 && (originalSize.width == 159 || originalSize.width > 150)) {
        // 如果是顶部动态弹出的传感器模块尺寸，直接抹平
        return CGSizeZero;
    }
    
    return originalSize;
}

// 3.【防止系统给该 Cell 分配 EdgeInsets 内边距】
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    UIEdgeInsets insets = %orig;
    // 如果顶部有留白 Padding，强行清空顶部 Inset
    if (insets.top > 0) {
        insets.top = 0;
    }
    return insets;
}

%end
