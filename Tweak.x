#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

#pragma mark - 1. 隐藏音频模块
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    v.userInteractionEnabled = NO;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
}
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 2. 隐藏视频模块
%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    v.userInteractionEnabled = NO;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0;
    self.view.frame = CGRectZero;
}
- (CGSize)preferredContentSize { return CGSizeZero; }
%end

#pragma mark - 3. 核心：collectionView 每次布局后强制压缩目标 cell
%hook UICollectionView
- (void)layoutSubviews {
    %orig;

    // 只处理控制中心的 collectionView
    NSString *cvCls = NSStringFromClass(self.class);
    BOOL isCC = [cvCls containsString:@"CCUI"];
    if(!isCC) {
        UIResponder *r = self.nextResponder;
        while(r) {
            if([NSStringFromClass([r class]) containsString:@"CCUIModule"]) {
                isCC = YES; break;
            }
            r = r.nextResponder;
        }
    }
    if(!isCC) return;

    // 遍历可见 cell，通过响应链找包含 RPCC 模块的 cell
    for(UICollectionViewCell *cell in self.visibleCells) {
        UIResponder *resp = cell;
        BOOL hit = NO;
        while(resp) {
            if([resp isKindOfClass:[UIViewController class]]) {
                NSString *rcls = NSStringFromClass([resp class]);
                if([rcls containsString:@"RPCCAudio"] || [rcls containsString:@"RPCCVideo"]) {
                    hit = YES; break;
                }
                for(id ch in [(UIViewController *)resp childViewControllers]) {
                    NSString *ccls = NSStringFromClass([ch class]);
                    if([ccls containsString:@"RPCCAudio"] || [ccls containsString:@"RPCCVideo"]) {
                        hit = YES; break;
                    }
                }
                if(hit) break;
            }
            resp = resp.nextResponder;
        }
        if(hit) {
            CGRect f = cell.frame;
            f.size.height = 0;
            cell.frame = f;
            cell.hidden = YES;
            cell.alpha = 0;
        }
    }
}
%end