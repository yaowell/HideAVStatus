#import <UIKit/UIKit.h>

#pragma mark - 工具函数：判断是否是目标模块
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

#pragma mark - 第一层：拦截数据源 setter（最干净，从数组里删掉）
%hook CCUIModuleCollectionViewController

- (void)setModuleContainerViewControllers:(NSArray *)controllers {
    NSMutableArray *filtered = [NSMutableArray array];
    for(id obj in controllers) {
        if(isTargetModule(obj)) {
            NSLog(@"[HideAV] [Layer1] filtered: %@", NSStringFromClass([obj class]));
            continue;
        }
        [filtered addObject:obj];
    }
    %orig(filtered);
}

// 兼容下划线命名的版本
- (void)set_moduleContainerViewControllers:(NSArray *)controllers {
    NSMutableArray *filtered = [NSMutableArray array];
    for(id obj in controllers) {
        if(isTargetModule(obj)) {
            NSLog(@"[HideAV] [Layer1b] filtered: %@", NSStringFromClass([obj class]));
            continue;
        }
        [filtered addObject:obj];
    }
    %orig(filtered);
}

#pragma mark - 第二层：viewWillAppear 兜底（直接改数组 + reload）
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
                        NSLog(@"[HideAV] [Layer2] removed via '%@': %@", key, NSStringFromClass([obj class]));
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

#pragma mark - 第三层：Layout 兜底（size 强制归零，消除占位）
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
                NSLog(@"[HideAV] [Layer3] zero-size at %@", attr.indexPath);
                continue;
            }
        } @catch(NSException *e) {}
        [result addObject:attr];
    }
    return result;
}

%end

#pragma mark - 第四层：模块自身兜底（让模块大小为0 + 隐藏）
%hook RPCCAudioSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)viewDidLoad { %orig; self.view.hidden = YES; self.view.alpha = 0; }
%end

%hook RPCCVideoSettingsModuleViewController
- (CGSize)preferredContentSize { return CGSizeZero; }
- (void)viewDidLoad { %orig; self.view.hidden = YES; self.view.alpha = 0; }
%end