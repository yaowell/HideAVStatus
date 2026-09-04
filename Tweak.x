#import <UIKit/UIKit.h>

#pragma mark - 工具
static BOOL isTargetClass(id obj) {
    if(!obj) return NO;
    NSString *cls = NSStringFromClass([obj class]);
    return [cls containsString:@"RPCCAudioSettings"] ||
           [cls containsString:@"RPCCVideoSettings"];
}

static void compress(UIView *v) {
    if(!v) return;
    CGRect f = v.frame;
    f.size.height = 0;
    v.frame = f;
    v.hidden = YES;
    v.alpha = 0;
    for(NSLayoutConstraint *c in v.constraints) {
        if(c.firstAttribute == NSLayoutAttributeHeight ||
           c.secondAttribute == NSLayoutAttributeHeight) {
            c.constant = 0;
        }
    }
}

#pragma mark - 第一层：你原始的隐藏逻辑（已验证有效，保留不动）
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    id s = self;
    UIView *v = [s valueForKey:@"view"];
    v.hidden = YES; v.alpha = 0; v.frame = CGRectZero;
}
- (CGSize)preferredContentSize {
    NSLog(@"[HideAV] audio preferredContentSize queried");
    return CGSizeZero;
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    id s = self;
    UIView *v = [s valueForKey:@"view"];
    v.hidden = YES; v.alpha = 0; v.frame = CGRectZero;
}
- (CGSize)preferredContentSize {
    NSLog(@"[HideAV] video preferredContentSize queried");
    return CGSizeZero;
}
%end

#pragma mark - 第二层：容器层面压缩（CCUIContentModuleContainerViewController 类名你原始代码已验证存在）
%hook CCUIContentModuleContainerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    id s = self;
    NSArray *children = [s valueForKey:@"childViewControllers"];
    id child = children.firstObject;
    if(!isTargetClass(child)) return;

    NSLog(@"[HideAV] [L2] container hit: %@", NSStringFromClass([child class]));

    UIView *containerView = [s valueForKey:@"view"];
    compress(containerView);

    // 往上压3层：contentView → cell → （可能还有一层）
    UIView *sv = containerView.superview;
    for(int i = 0; sv && i < 3; i++) {
        compress(sv);
        sv = sv.superview;
    }
}
%end

#pragma mark - 第三层：UICollectionView 兜底（标准 UIKit 类，100% 存在）
%hook UICollectionView
- (void)layoutSubviews {
    %orig;
    // 只处理控制中心的 collectionView
    UIResponder *r = self.nextResponder;
    BOOL isCC = NO;
    while(r) {
        if([NSStringFromClass([r class]) containsString:@"CCUIModuleCollection"]) {
            isCC = YES; break;
        }
        r = r.nextResponder;
    }
    if(!isCC) return;

    for(UICollectionViewCell *cell in self.visibleCells) {
        UIResponder *resp = cell;
        BOOL hit = NO;
        while(resp) {
            if([resp isKindOfClass:[UIViewController class]]) {
                if(isTargetClass(resp)) { hit = YES; break; }
                NSArray *ch = [resp valueForKey:@"childViewControllers"];
                for(id c in ch) {
                    if(isTargetClass(c)) { hit = YES; break; }
                }
                if(hit) break;
            }
            resp = resp.nextResponder;
        }
        if(hit) {
            NSLog(@"[HideAV] [L3] cell compressed");
            compress(cell);
            compress(cell.contentView);
        }
    }
}
%end