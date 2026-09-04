#import <UIKit/UIKit.h>

@protocol CCUIContentModule <NSObject>
@end

%hook CCUIContentModuleContainerViewController

- (id<CCUIContentModule>)contentModule {
    id selfId = self;
    id childVc = [selfId childViewControllers].firstObject;
    if(childVc) {
        NSString *cls = NSStringFromClass([childVc class]);
        if ([cls isEqualToString:@"RPCCAudioSettingsModuleViewController"] ||
            [cls isEqualToString:@"RPCCVideoSettingsModuleViewController"]) {
            return nil;
        }
    }
    return %orig;
}

%end

%hook CCUIModuleCollectionViewLayout

- (NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSArray *attrsArr = %orig;
    NSMutableArray *final = [NSMutableArray array];
    Class containerClass = NSClassFromString(@"CCUIContentModuleContainerViewController");
    Class collVcClass = NSClassFromString(@"CCUIModuleCollectionViewController");

    for(UICollectionViewLayoutAttributes *attr in attrsArr) {
        id delegateObj = self.collectionView.delegate;
        if(![delegateObj isKindOfClass:collVcClass]){
            [final addObject:attr];
            continue;
        }
        NSArray *containers = [delegateObj valueForKeyPath:@"moduleContainerViewControllers"];
        if(attr.indexPath.item >= containers.count) {
            [final addObject:attr];
            continue;
        }
        id containerObj = containers[attr.indexPath.item];
        if(![containerObj isKindOfClass:containerClass]){
            [final addObject:attr];
            continue;
        }
        id inner = [containerObj childViewControllers].firstObject;
        if(!inner) {
            [final addObject:attr];
            continue;
        }
        NSString *innerCls = NSStringFromClass([inner class]);
        if([innerCls isEqualToString:@"RPCCAudioSettingsModuleViewController"] ||
           [innerCls isEqualToString:@"RPCCVideoSettingsModuleViewController"]){
            continue;
        }
        [final addObject:attr];
    }
    return final;
}

%end