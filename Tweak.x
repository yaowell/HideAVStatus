#import <UIKit/UIKit.h>

#pragma mark - 工具函数（参数全是 id，不碰 self）
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

static void setViewOf(id obj, UIView *v) { [obj setValue:v forKey:@"view"]; }
static UIView *getViewOf(id obj) { return [obj valueForKey:@"view"]; }
static NSArray *getChildVCs(id obj) { return [obj valueForKey:@"childViewControllers"]; }

#pragma mark - 第一层：隐藏模块
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    setViewOf(self, emptyView);
}
- (void)viewDidLoad {
    %orig;
    UIView *v = getViewOf(self);
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
    setViewOf(self, emptyView);
}
- (void)viewDidLoad {
    %orig;
    UIView *v = getViewOf(self);
    v.hidden = YES; v.alpha = 0; v.frame = CGRectZero;
}
- (CGSize)preferredContentSize {
    NSLog(@"[HideAV] video preferredContentSize queried");
    return CGSizeZero;
}
%end

#pragma mark - 第二层：容器层面压缩
%hook CCUIContentModuleContainerViewController
- (void)viewDidLayoutSubviews {
    %orig;
    NSArray *children = getChildVCs(self);
    id child = children.firstObject;
    if(!isTargetClass(child)) return;

    NSLog(@"[HideAV] [L2] container hit: %@", NSStringFromClass([child class]));

    UIView *containerView = getViewOf(self);
    compress(containerView);

    UIView *sv = containerView.superview;
    for(int i = 0; sv && i < 3; i++) {
        compress(sv);
        sv = sv.superview;
    }
}
%end

#pragma mark - 第三层：UICollectionView 兜底（系统类，self 可直接用）
%hook UICollectionView
- (void)layoutSubviews {
    %orig;
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
                NSArray *ch = getChildVCs(resp);
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