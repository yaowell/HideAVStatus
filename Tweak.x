#import <UIKit/UIKit.h>

static void BMPrintVCChain(UIViewController *vc)
{
    NSLog(@"========== RPCC VC CHAIN ==========");

    int i = 0;

    while (vc && i < 15) {

        NSLog(@"[RPCC] VC[%d] = %@",
              i,
              NSStringFromClass([vc class]));

        NSLog(@"[RPCC]     view = %@ frame=%@",
              NSStringFromClass([vc.view class]),
              NSStringFromCGRect(vc.view.frame));

        vc = vc.parentViewController;
        i++;
    }

    NSLog(@"========== END VC CHAIN ==========");
}


static void BMPrintViewChain(UIView *view)
{
    NSLog(@"========== RPCC VIEW CHAIN ==========");

    int i = 0;

    while (view && i < 15) {

        NSLog(@"[RPCC] VIEW[%d] = %@ frame=%@ hidden=%d",
              i,
              NSStringFromClass([view class]),
              NSStringFromCGRect(view.frame),
              view.hidden);

        view = view.superview;
        i++;
    }

    NSLog(@"========== END VIEW CHAIN ==========");
}


// ============================================================
// 视频
// ============================================================

%hook RPCCVideoSettingsModuleViewController

- (void)viewDidAppear:(BOOL)animated
{
    %orig;

    static BOOL printed = NO;

    if (!printed) {
        printed = YES;

        BMPrintVCChain(self);
        BMPrintViewChain(self.view);
    }
}

%end


// ============================================================
// 音频
// ============================================================

%hook RPCCAudioSettingsModuleViewController

- (void)viewDidAppear:(BOOL)animated
{
    %orig;

    static BOOL printed = NO;

    if (!printed) {
        printed = YES;

        BMPrintVCChain(self);
        BMPrintViewChain(self.view);
    }
}

%end