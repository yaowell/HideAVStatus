#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

void dumpViewAndLayers(UIView *view, int depth) {
    if (!view) return;
    
    NSString *indent = [@"" stringByPaddingToLength:depth * 2 withString:@" " startingAtIndex:0];
    
    // 加个明确的前缀 [CC_DEBUG]，方便后续在终端筛选
    NSLog(@"[CC_DEBUG] %@View: %@ | Frame: %@", indent, NSStringFromClass([view class]), NSStringFromCGRect(view.frame));
    
    if (view.layer.sublayers) {
        for (CALayer *layer in view.layer.sublayers) {
            NSLog(@"[CC_DEBUG] %@  └─ Layer: %@ | Bounds: %@", indent, NSStringFromClass([layer class]), NSStringFromCGRect(layer.bounds));
        }
    }
    
    for (UIView *subview in view.subviews) {
        dumpViewAndLayers(subview, depth + 1);
    }
}
