#import <UIKit/UIKit.h>

@interface CCUIModuleCollectionViewController : UIViewController
@property (nonatomic, copy) NSArray *moduleIdentifiers;
@end

%hook CCUIModuleCollectionViewController

// 1. 从数据源层彻底剔除这两个 ID，防止控制中心为其分配顶部 Grid 空间
- (void)setModuleIdentifiers:(NSArray *)moduleIdentifiers {
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *identifier in moduleIdentifiers) {
        if (![identifier containsString:@"AudioConferenceControlCenter"] &&
            ![identifier containsString:@"VideoConferenceControlCenter"]) {
            [filtered addObject:identifier];
        }
    }
    %orig([filtered copy]);
}

// 2. 安全拦截：阻断顶部 Module 的初始化绑定，如果遇到直接返回 orig 的空处理而非 nil，防止解引用崩溃
- (id)_setupAndAddModuleViewControllerToHierarchy:(id)moduleViewController {
    NSString *desc = [moduleViewController description];
    if ([desc containsString:@"AudioConferenceControlCenter"] ||
        [desc containsString:@"VideoConferenceControlCenter"]) {
        return nil; // 如果这一步触发 Safe Mode，只需注释掉此函数即可
    }
    return %orig;
}

%end
