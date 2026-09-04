#import <UIKit/UIKit.h>

@interface CCUIModuleCollectionViewController : UIViewController
@end

%hook CCUIModuleCollectionViewController

// 1. 当系统请求获取最顶部的模块 View 时，直接返回 nil（不渲染，零开销）
- (id)topmostModuleView {
    return nil;
}

// 2. 当系统尝试设置/更新 topmostModuleIdentifier 时，置为空
- (id)_topmostModuleIdentifier {
    return nil;
}

%end
