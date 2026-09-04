#import <UIKit/UIKit.h>

// ============================================================
// 显式声明真实类
// ============================================================

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end


// ============================================================
// 打印 ViewController 父级链
// ============================================================

static void BMPrintVCChain(UIViewController *vc)
{
    NSLog(@"========== [RPCC] VC CHAIN BEGIN ==========");

    int index = 0;

    while (vc != nil && index < 15) {

        NSLog(@"[RPCC] VC[%d] = %@",
              index,
              NSStringFromClass([vc class]));

        UIView *view = vc.view;

        NSLog(@"[RPCC]      view = %@",
              NSStringFromClass([view class]));

        NSLog(@"[RPCC]      frame = %@",
              NSStringFromCGRect(view.frame));

        vc = vc.parentViewController;

        index++;
    }

    NSLog(@"========== [RPCC] VC CHAIN END ==========");
}


// ============================================================
// 打印 View 的 superview 链
// ============================================================

static void BMPrintViewChain(UIView *view)
{
    NSLog(@"========== [RPCC] VIEW CHAIN BEGIN ==========");

    int index = 0;

    while (view != nil && index < 15) {

        NSLog(@"[RPCC] VIEW[%d] = %@",
              index,
              NSStringFromClass([view class]));

        NSLog(@"[RPCC]      frame = %@",
              NSStringFromCGRect(view.frame));

        NSLog(@"[RPCC]      hidden = %d",
              view.hidden);

        view = view.superview;

        index++;
    }

    NSLog(@"========== [RPCC] VIEW CHAIN END ==========");
}


// ============================================================
// 视频模块
// ============================================================

%hook RPCCVideoSettingsModuleViewController

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    %orig;

    UIViewController *vc = (UIViewController *)self;

    NSLog(@"[RPCC] ========================================");
    NSLog(@"[RPCC] VIDEO MODULE CREATED");
    NSLog(@"[RPCC] VIDEO parent = %@",
          parent ? NSStringFromClass([parent class]) : @"nil");

    BMPrintVCChain(vc);

    UIView *view = vc.view;

    NSLog(@"[RPCC] VIDEO view = %@",
          NSStringFromClass([view class]));

    NSLog(@"[RPCC] VIDEO superview = %@",
          view.superview ?
          NSStringFromClass([view.superview class]) :
          @"nil");

    BMPrintViewChain(view);

    NSLog(@"[RPCC] ========================================");
}

%end


// ============================================================
// 音频模块
// ============================================================

%hook RPCCAudioSettingsModuleViewController

- (void)didMoveToParentViewController:(UIViewController *)parent
{
    %orig;

    UIViewController *vc = (UIViewController *)self;

    NSLog(@"[RPCC] ========================================");
    NSLog(@"[RPCC] AUDIO MODULE CREATED");
    NSLog(@"[RPCC] AUDIO parent = %@",
          parent ? NSStringFromClass([parent class]) : @"nil");

    BMPrintVCChain(vc);

    UIView *view = vc.view;

    NSLog(@"[RPCC] AUDIO view = %@",
          NSStringFromClass([view class]));

    NSLog(@"[RPCC] AUDIO superview = %@",
          view.superview ?
          NSStringFromClass([view.superview class]) :
          @"nil");

    BMPrintViewChain(view);

    NSLog(@"[RPCC] ========================================");
}

%end