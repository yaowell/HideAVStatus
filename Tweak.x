#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end

// 1. 先确保模块内部 VC 实体彻底移除（这步之前已经成功了）
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    v.hidden = YES;
    self.view = v;
}
- (void)viewDidLoad {
    %orig;
    [self.view removeFromSuperview];
}
%end

// 2. 针对包含这两个 VC 的外层 Cell/View，直接在 layoutSubviews 时从物理上抹平
%hook UIView

- (void)layoutSubviews {
    %orig;
    
    // 获取当前 View 关联的 View Controller
    UIResponder *responder = self;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;
            NSString *clsName = NSStringFromClass([vc class]);
            
            // 如果这个 View 属于 Audio/Video 模块，直接压扁并隐藏
            if ([clsName containsString:@"RPCCAudio"] || [clsName containsString:@"RPCCVideo"]) {
                self.hidden = YES;
                self.alpha = 0.0;
                self.frame = CGRectZero;
                
                // 同时顺便把包裹它的 Cell 容器也一并压扁
                if (self.superview && ![NSStringFromClass([self.superview class]) containsString:@"UIWindow"]) {
                    self.superview.hidden = YES;
                    self.superview.frame = CGRectMake(self.superview.frame.origin.x, self.superview.frame.origin.y, 0, 0);
                }
            }
            break;
        }
        responder = [responder nextResponder];
    }
}

%end
