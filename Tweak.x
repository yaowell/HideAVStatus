#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void CCWriteLog(NSString *text) {
    NSString *path = @"/var/mobile/Documents/CC_LayoutProbe.log";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!old) old = @"";
    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    NSString *out = [old stringByAppendingString:line];
    [out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

%hook CCUIModuleCollectionViewController

- (CGSize)layoutSizeForModuleIdentifier:(NSString *)identifier
                         forOrientation:(NSInteger)orientation
{
    CGSize size = %orig;

    CCWriteLog([NSString stringWithFormat:
        @"[layoutSizeForModuleIdentifier] id=%@ orientation=%ld size=%.2fx%.2f",
        identifier ?: @"(nil)",
        (long)orientation,
        size.width,
        size.height]);

    return size;
}

%end

%ctor {
    CCWriteLog(@"==============================================");
    CCWriteLog(@"[CCUI Layout Probe]");
    CCWriteLog(@"Hook: CCUIModuleCollectionViewController");
    CCWriteLog(@"Mode: Original value only");
    CCWriteLog(@"==============================================");
}