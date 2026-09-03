#import <UIKit/UIKit.h>

// ============================================================
// 接口声明
// ============================================================

@interface RPCCAudioSettingsModuleViewController : UIViewController
@end

@interface RPCCVideoSettingsModuleViewController : UIViewController
@end


// ============================================================
// 判断是否为我们要隐藏的 RPCC 模块
// ============================================================

static BOOL BMIsRPCCHiddenModule(UIViewController *vc)
{
    NSString *cls = NSStringFromClass([vc class]);

    return [cls isEqualToString:@"RPCCAudioSettingsModuleViewController"] ||
           [cls isEqualToString:@"RPCCVideoSettingsModuleViewController"];
}


// ============================================================
// 麦克风模式
// ============================================================

%hook RPCCAudioSettingsModuleViewController

- (void)loadView
{
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];

    emptyView.hidden = YES;
    emptyView.alpha = 0.0;
    emptyView.userInteractionEnabled = NO;

    self.view = emptyView;
}

- (void)viewDidLoad
{
    %orig;

    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.userInteractionEnabled = NO;
}

- (CGSize)preferredContentSize
{
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
{
    return CGSizeZero;
}

- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container
                               withParentContainerSize:(CGSize)parentSize
{
    return CGSizeZero;
}

- (void)viewDidLayoutSubviews
{
    %orig;

    self.view.hidden = YES;
    self.view.alpha = 0.0;
}

%end


// ============================================================
// 视讯效果
// ============================================================

%hook RPCCVideoSettingsModuleViewController

- (void)loadView
{
    UIView *emptyView = [[UIView alloc] initWithFrame:CGRectZero];

    emptyView.hidden = YES;
    emptyView.alpha = 0.0;
    emptyView.userInteractionEnabled = NO;

    self.view = emptyView;
}

- (void)viewDidLoad
{
    %orig;

    self.view.hidden = YES;
    self.view.alpha = 0.0;
    self.view.userInteractionEnabled = NO;
}

- (CGSize)preferredContentSize
{
    return CGSizeZero;
}

- (CGSize)systemLayoutSizeFittingSize:(CGSize)targetSize
{
    return CGSizeZero;
}

- (CGSize)sizeForChildContentContainer:(id<UIContentContainer>)container
                               withParentContainerSize:(CGSize)parentSize
{
    return CGSizeZero;
}

- (void)viewDidLayoutSubviews
{
    %orig;

    self.view.hidden = YES;
    self.view.alpha = 0.0;
}

%end