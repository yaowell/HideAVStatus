#import <UIKit/UIKit.h>

%hook CCUIHeaderViewController

- (void)viewDidLoad {
    %orig;

    if (self.view) {
        self.view.hidden = YES;
    }
}

- (void)viewWillLayoutSubviews {
    %orig;

    if (self.view) {
        self.view.hidden = YES;
    }
}

%end