#import <UIKit/UIKit.h>

static void CCWriteLog(NSString *text) {
    NSString *path = @"/var/mobile/Documents/CC_RPCC_AudioHeight.log";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!old) old = @"";
    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    [old stringByAppendingString:line];
    [[old stringByAppendingString:line] writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

%hook RPCCAudioSettingsModuleViewController

- (double)preferredExpandedContentHeight {
    double height = %orig;

    CCWriteLog([NSString stringWithFormat:
        @"[preferredExpandedContentHeight] original=%.2f",
        height]);

    return height;
}

%end

%ctor {
    CCWriteLog(@"==============================================");
    CCWriteLog(@"[RPCC Audio Height Probe]");
    CCWriteLog(@"Hook: preferredExpandedContentHeight");
    CCWriteLog(@"Mode: Original value only");
    CCWriteLog(@"==============================================");
}