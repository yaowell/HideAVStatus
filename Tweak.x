#import <UIKit/UIKit.h>

#pragma mark - 工具函数
static BOOL isTargetModule(id obj) {
    if(!obj) return NO;
    id inner = nil;
    @try { inner = [obj valueForKeyPath:@"childViewControllers.firstObject"]; }
    @catch(NSException *e) {}
    if(!inner) inner = obj;
    NSString *cls = NSStringFromClass([inner class]);
    return [cls containsString:@"RPCCAudioSettings"] ||
           [cls containsString:@"RPCCVideoSettings"];
}

static void hideViewOf(id obj) {
    UIView *v = [obj valueForKey:@"view"];
    if(v) { v.hidden = YES; v.alpha = 0; }
}

#pragma mark - 第一层：拦截数据源 setter
%hook CCUIModuleCollectionViewController

- (void)setModuleContainerViewControllers:(NSArray *)controllers {
    NSMutableArray *filtered = [NSMutableArray array];
    for(id obj in controllers) {
        if(isTargetModule(obj)) {
            NSLog(@"[HideAV] [L1] filtered: %@", NSStringFromClass([obj class]));
            continue;
        }
        [filtered addObject:obj];
    }
    %orig(filtered);
}

- (void)set_moduleContainerViewControllers:(NSArray *)controllers {
    NSMutableArray *filtered = [NSMutableArray array];
    for(id obj in controllers) {
        if(isTargetModule(obj)) {
            NSLog(@"[HideAV] [L1b] filtered: %@", NSStringFromClass([obj class]));
            continue;
        }
        [filtered addObject:obj];
    }
    %orig(filtered);
}

#pragma mark - 第二层：viewWillAppear 兜底
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    id selfId = self;
    NSArray *keys = @[
        @"moduleContainerViewControllers",
        @"_moduleContainerViewControllers",
        @"moduleContainers",
        @"_moduleContainers"
    ];
    for(NSString *key in keys) {
        @try {
            id val = [selfId valueForKey:key];
            if([val isKindOfClass:[NSArray class]]) {
                NSMutableArray *arr = [val mutableCopy];
                BOOL changed = NO;
                for(id obj in [arr copy]) {
                    if(isTargetModule(obj)) {
                        [arr removeObject:obj];
                        changed = YES;
                        NSLog(@"[HideAV] [L2] removed via '%@': %@", key, NSStringFromClass([obj class]));
                    }
                }
                if(changed) {
                    [selfId setValue:arr forKey:key];
                    UICollectionView *cv = [selfId valueForKey:@"collectionView"];
                    if(cv) [cv reloadData];
                }
                break;
            }
        } @catch(NSException *e) {}
    }
}

%end

#pragma mark - 第三层：Layout 兜底
%hook CCUIModuleCollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attrs = %orig;
    id selfId = self;
    UICollectionView *cv = [selfId valueForKey:@"collectionView"];
    if(!cv) return attrs;
    id dataSource = cv.dataSource;
    if(!dataSource) return attrs;

    NSMutableArray *result = [NSMutableArray array];
    for(UICollectionViewLayoutAttributes *attr in attrs) {
        @try {
            UICollectionViewCell *cell = [dataSource collectionView:cv cellForItemAtIndexPath:attr.indexPath];
            id contentVc = [cell valueForKeyPath:@"contentViewController"];
            if(!contentVc) contentVc = [cell valueForKeyPath:@"_contentViewController"];
            if(isTargetModule(contentVc)) {
                UICollectionViewLayoutAttributes *newAttr = [attr copy];
                newAttr.size = CGSizeZero;
                newAttr.alpha = 0;
                newAttr.hidden = YES;
                [result addObject:newAttr];
                NSLog(@"[HideAV] [L3] zero-size at %@", attr.indexPath);
                continue;
            }
        } @catch(NSException *e) {}
        [result addObject:attr];
    }
    return result;
}

%end

#pragma mark - 第四层：模块自身兜底（全部 id + KVC）
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)viewDidLoad {
    %orig;
    hideViewOf(self);
}
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)viewDidLoad {
    %orig;
    hideViewOf(self);
}
%end