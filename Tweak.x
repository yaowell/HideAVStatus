#import <UIKit/UIKit.h>

%hook CCUIHeaderViewController

- (void)viewDidLoad {
    %orig;

    UIViewController *vc = (UIViewController *)self;
    UIView *headerView = vc.view;

    if (headerView) {
        headerView.hidden = YES;
    }
}

- (void)viewWillLayoutSubviews {
    %orig;

    UIViewController *vc = (UIViewController *)self;
    UIView *headerView = vc.view;

    if (headerView) {
        headerView.hidden = YES;
    }
}

%end