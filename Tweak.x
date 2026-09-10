#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/CC_ModuleProbe.log";

static void CCWriteLog(NSString *text) {
    NSString *old = [NSString stringWithContentsOfFile:kLogPath
                                               encoding:NSUTF8StringEncoding
                                                  error:nil];
    if (!old) old = @"";

    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    [old stringByAppendingString:line];

    [[old stringByAppendingString:line]
        writeToFile:kLogPath
        atomically:YES
        encoding:NSUTF8StringEncoding
        error:nil];
}

static BOOL CCIsInterestingInstance(id instance) {
    static NSMutableSet *knownObjects;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        knownObjects = [NSMutableSet set];
    });

    NSString *key = [NSString stringWithFormat:@"%p", instance];

    @synchronized (knownObjects) {
        if ([knownObjects containsObject:key]) {
            return NO;
        }

        [knownObjects addObject:key];

        if (knownObjects.count > 200) {
            [knownObjects removeAllObjects];
        }
    }

    return YES;
}

%hook CCUIModuleInstance

- (id)module {
    id result = %orig;

    @try {
        NSString *moduleClass =
            result ? NSStringFromClass([result class]) : @"(nil)";

        NSString *moduleDesc =
            result ? [result description] : @"(nil)";

        CCWriteLog([NSString stringWithFormat:
            @"[module] instance=%p moduleClass=%@ module=%@",
            self,
            moduleClass,
            moduleDesc]);

    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[module] instance=%p EXCEPTION=%@",
            self,
            exception]);
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
        CCWriteLog(@"[CCUIModuleInstance module Probe]");
        CCWriteLog(@"Mode: ORIGINAL VALUE ONLY");
        CCWriteLog(@"==============================================");
    });
}