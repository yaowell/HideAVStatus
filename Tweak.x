#import <UIKit/UIKit.h>

static void CCWriteLog(NSString *text) {
    NSString *path = @"/var/mobile/Documents/CC_ModuleInstances.log";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!old) old = @"";
    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    NSString *out = [old stringByAppendingString:line];
    [out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static void CCLogInstances(NSString *method, NSArray *instances) {
    CCWriteLog([NSString stringWithFormat:@"[%@] count=%lu",
                method,
                (unsigned long)instances.count]);

    NSUInteger index = 0;

    for (id instance in instances) {
        NSString *className = NSStringFromClass([instance class]);
        NSString *description = [instance description];

        CCWriteLog([NSString stringWithFormat:
                    @"  [%lu] class=%@ object=%@",
                    (unsigned long)index,
                    className ?: @"(nil)",
                    description ?: @"(nil)"]);

        index++;
    }
}

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *result = %orig;
    CCLogInstances(@"moduleInstances", result);
    return result;
}

- (NSArray *)enabledModuleInstances {
    NSArray *result = %orig;
    CCLogInstances(@"enabledModuleInstances", result);
    return result;
}

%end

%ctor {
    CCWriteLog(@"==============================================");
    CCWriteLog(@"[CC Module Instance Type Probe]");
    CCWriteLog(@"Hook: CCUIModuleInstanceManager");
    CCWriteLog(@"Mode: Original value only");
    CCWriteLog(@"==============================================");
}