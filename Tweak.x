#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

void dumpViewAndLayers(UIView *view, int depth) {
    if (!view) return;
    
    // 缩进，方便在设备日志里看清层级关系
    NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
    
    // 1. 打印当前 View 的类名和真实 Frame
    NSLog(@"%@View: %@ | Frame: %@", indent, NSStringFromClass([view class]), NSStringFromCGRect(view.frame));
    
    // 2. 打印当前 View 挂载的所有 CALayer（控制中心的核心视觉元素全在这）
    if (view.layer.sublayers) {
        for (CALayer *layer in view.layer.sublayers) {
            NSLog(@"%@  └─ Layer: %@ | Bounds: %@", indent, NSStringFromClass([layer class]), NSStringFromCGRect(layer.bounds));
        }
    }
    
    // 3. 递归向下遍历所有的子 View
    for (UIView *subview in view.subviews) {
        dumpViewAndLayers(subview, depth + 1);
    }
}
