#import <UIKit/UIKit.h>

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end
@interface RPCCVideoSettingsModuleViewController : UIViewController
@end
@class CCUIModuleCollectionViewController;

#pragma mark - 1. 视图隐藏兜底（保留你的原始逻辑）
%hook RPCCAudioSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}
%end

%hook RPCCVideoSettingsModuleViewController
- (void)loadView {
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];
    emptyView.hidden = YES;
    emptyView.userInteractionEnabled = NO;
    self.view = emptyView;
}
- (void)viewDidLoad {
    %orig;
    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.frame = CGRectZero;
    [self.view removeFromSuperview];
}
%end

#pragma mark - 2. 根源消除：从启用列表过滤模块
%hook CCUIModuleCollectionViewController

- (id)orderedEnabledModuleIdentifiersForSettingsManager:(id)manager {
    NSArray *original = %orig;
    if(!original) return original;
    
    NSMutableArray *filtered = [original mutableCopy];
    for(NSString *identifier in [original copy]) {
        BOOL shouldRemove = 
            [identifier containsString:@"replaykit.Audio"] ||
            [identifier containsString:@"replaykit.Video"] ||
            [identifier containsString:@"AudioConference"] ||
            [identifier containsString:@"VideoConference"];
        
        if(shouldRemove) {
            [filtered removeObject:identifier];
            NSLog(@"[HideAV] 过滤模块: %@", identifier);
        }
    }
    return filtered;
}

%end