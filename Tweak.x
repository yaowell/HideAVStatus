#import <UIKit/UIKit.h>

@protocol CCUIContentModule <NSObject>
@end

@interface CCUIContentModuleContainerViewController : UIViewController
@property (nonatomic, strong, readwrite) id<CCUIContentModule> contentModule;
@end

@interface CCUIModuleCollectionViewLayout : UICollectionViewLayout
@end

%hook CCUIContentModuleContainerViewController

- (id<CCUIContentModule>)contentModule {
    UIViewController *childVc = self.childViewControllers.firstObject;
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
    for(UICollectionViewLayoutAttributes *attr in attrsArr) {
        UIViewController *collectionVc = [(UICollectionView *)self.collectionView delegate];
        if(![collectionVc isKindOfClass:NSClassFromString(@"CCUIModuleCollectionViewController")]){
            [final addObject:attr];
            continue;
        }
        NSArray *containers = [collectionVc valueForKeyPath:@"moduleContainerViewControllers"];
        if(attr.indexPath.item >= containers.count) {
            [final addObject:attr];
            continue;
        }
        id containerObj = containers[attr.indexPath.item];
        if(![containerObj isKindOfClass:[CCUIContentModuleContainerViewController class]]){
            [final addObject:attr];
            continue;
        }
        CCUIContentModuleContainerViewController *containerVC = containerObj;
        UIViewController *inner = containerVC.childViewControllers.firstObject;
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