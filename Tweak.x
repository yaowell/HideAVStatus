#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/RPCC_VCProbe.log";

static void CCWriteLog(NSString *text) {
    NSString *old = [NSString stringWithContentsOfFile:kLogPath
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    if (!old) old = @"";

    NSString *line = [NSString stringWithFormat:@"%@\n", text];

    [[old stringByAppendingString:line]
        writeToFile:kLogPath
        atomically:YES
        encoding:NSUTF8StringEncoding
        error:nil];
}

%hook RPCCAudioSettingsModule

- (id)contentViewControllerForContext:(id)context {
    id result = %orig;

    @try {
        CCWriteLog([NSString stringWithFormat:
            @"[AUDIO contentVC] result=%p class=%@ object=%@",
            result,
            result ? NSStringFromClass([result class]) : @"(nil)",
            result ?: @"(nil)"]);
    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[AUDIO contentVC] EXCEPTION=%@", exception]);
    }

    return result;
}

- (id)backgroundViewControllerForContext:(id)context {
    id result = %orig;

    @try {
        CCWriteLog([NSString stringWithFormat:
            @"[AUDIO backgroundVC] result=%p class=%@ object=%@",
            result,
            result ? NSStringFromClass([result class]) : @"(nil)",
            result ?: @"(nil)"]);
    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[AUDIO backgroundVC] EXCEPTION=%@", exception]);
    }

    return result;
}

%end

%hook RPCCVideoSettingsModule

- (id)contentViewControllerForContext:(id)context {
    id result = %orig;

    @try {
        CCWriteLog([NSString stringWithFormat:
            @"[VIDEO contentVC] result=%p class=%@ object=%@",
            result,
            result ? NSStringFromClass([result class]) : @"(nil)",
            result ?: @"(nil)"]);
    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[VIDEO contentVC] EXCEPTION=%@", exception]);
    }

    return result;
}

- (id)backgroundViewControllerForContext:(id)context {
    id result = %orig;

    @try {
        CCWriteLog([NSString stringWithFormat:
            @"[VIDEO backgroundVC] result=%p class=%@ object=%@",
            result,
            result ? NSStringFromClass([result class]) : @"(nil)",
            result ?: @"(nil)"]);
    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[VIDEO backgroundVC] EXCEPTION=%@", exception]);
    }

    return result;
}

%end

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSFileManager defaultManager]
            removeItemAtPath:kLogPath
                      error:nil];

        CCWriteLog(@"==============================================");
        CCWriteLog(@"[RPCC ViewController Probe]");
        CCWriteLog(@"Mode: ORIGINAL VALUE ONLY");
        CCWriteLog(@"==============================================");
    });
}