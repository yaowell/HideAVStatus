#import <UIKit/UIKit.h>

static void CCWriteLog(NSString *text) {
    NSString *path = @"/var/mobile/Documents/CC_ModuleInstances.log";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!old) old = @"";
    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    NSString *out = [old stringByAppendingString:line];
    [out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

static NSString *CCIdentifier(id instance) {
    NSString *identifier = nil;

    @try {
        identifier = [instance valueForKey:@"moduleIdentifier"];

        if (!identifier)
            identifier = [instance valueForKey:@"identifier"];

        if (!identifier)
            identifier = [[instance valueForKey:@"moduleRepresentation"] valueForKey:@"identifier"];
    }
    @catch (NSException *exception) {
    }

    return identifier ?: @"(unknown)";
}

static void CCLogInstances(NSString *method, NSArray *instances) {
    CCWriteLog([NSString stringWithFormat:
        @"[%@] count=%lu",
        method,
        (unsigned long)instances.count]);

    NSUInteger index = 0;

    for (id instance in instances) {
        NSString *identifier = CCIdentifier(instance);

        CCWriteLog([NSString stringWithFormat:
            @"  [%lu] %@",
            (unsigned long)index,
            identifier]);

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
    CCWriteLog(@"[CC Module Instance Probe]");
    CCWriteLog(@"Hook: CCUIModuleInstanceManager");
    CCWriteLog(@"Mode: Original value only");
    CCWriteLog(@"==============================================");
}