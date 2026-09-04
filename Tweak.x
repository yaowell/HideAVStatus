#import <UIKit/UIKit.h>

// 1. 显式声明接口，防止编译警告和类型识别错误
@interface CCUIModuleCollectionViewController : UIViewController
- (NSString *)_topmostModuleIdentifier;
- (id)topmostModuleView;
@end

%hook CCUIModuleCollectionViewController

// 2. 仅拦截 Getter 方法，直接返回 nil。
// 拿着真实 ID 的查询全部返回 nil，系统就不会去触发顶部的布局分配。

- (NSString *)_topmostModuleIdentifier {
    return nil;
}

- (id)topmostModuleView {
    return nil;
}

%end
