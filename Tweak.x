#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@end

#pragma mark - 全局记录目标 cell
static NSMutableSet *g_targetCells = nil;

static BOOL isCCCollectionView(UICollectionView *cv) {
    if(!cv) return NO;
    if([NSStringFromClass(cv.class) containsString:@"CCUI"]) return YES;
    UIResponder *r = cv.nextResponder;
    while(r) {
        if([NSStringFromClass([r class]) containsString:@"CCUIModule"]) return YES;
        r = r.nextResponder;
    }
    return NO;
}

#pragma mark - 1. 音频模块（你的原始隐藏逻辑）
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    [self.view removeFromSuperview];
}
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 2. 视频模块（你的原始隐藏逻辑）
%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    [self.view removeFromSuperview];
}
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 3. 容器：隐藏 + 记录 cell 指针
%hook CCUIContentModuleContainerViewController
- (void)viewWillLayoutSubviews {
    %orig;
    UIViewController *child = self.childViewControllers.firstObject;
    if(!child) return;
    NSString *cls = NSStringFromClass([child class]);
    if(![cls containsString:@"RPCCAudioSettings"] && ![cls containsString:@"RPCCVideoSettings"]) return;

    // 在 removeFromSuperview 之前，把 cell 记下来
    UIView *contentView = self.view.superview;
    UIView *cell = contentView.superview;
    if(cell) {
        if(!g_targetCells) g_targetCells = [NSMutableSet set];
        [g_targetCells addObject:cell];
    }

    // 你的原始隐藏逻辑
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}
%end

#pragma mark - 4. 核心：布局阶段把目标 cell 的 size 强制归零
%hook UICollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attrs = %orig;
    UICollectionView *cv = self.collectionView;
    if(!isCCCollectionView(cv) || !g_targetCells) return attrs;

    NSMutableArray *result = [NSMutableArray array];
    for(UICollectionViewLayoutAttributes *attr in attrs) {
        UICollectionViewCell *cell = [cv cellForItemAtIndexPath:attr.indexPath];
        if(cell && [g_targetCells containsObject:cell]) {
            UICollectionViewLayoutAttributes *newAttr = [attr copy];
            newAttr.size = CGSizeZero;
            newAttr.alpha = 0;
            newAttr.hidden = YES;
            [result addObject:newAttr];
        } else {
            [result addObject:attr];
        }
    }
    return result;
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewLayoutAttributes *attr = %orig;
    UICollectionView *cv = self.collectionView;
    if(!isCCCollectionView(cv) || !g_targetCells) return attr;
    UICollectionViewCell *cell = [cv cellForItemAtIndexPath:indexPath];
    if(cell && [g_targetCells containsObject:cell]) {
        attr.size = CGSizeZero;
        attr.alpha = 0;
        attr.hidden = YES;
    }
    return attr;
}

%end