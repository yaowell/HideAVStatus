#import <UIKit/UIKit.h>

%hook CCUIHeaderViewController

- (void)viewDidLoad {
    %orig;

    UIView *headerView = [self view];
    if (headerView) {
        [headerView setHidden:YES];
    }
}

- (void)viewWillLayoutSubviews {
    %orig;

    UIView *headerView = [self view];
    if (headerView) {
        [headerView setHidden:YES];
    }
}

%end