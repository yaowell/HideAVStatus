#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static void CCWriteLog(NSString *text) {
    NSString *path = @"/var/mobile/Documents/CC_InstanceMethods.log";
    NSString *old = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    if (!old) old = @"";
    NSString *line = [NSString stringWithFormat:@"%@\n", text];
    NSString *out = [old stringByAppendingString:line];
    [out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        Class cls = NSClassFromString(@"CCUIModuleInstance");

        CCWriteLog(@"==============================================");
        CCWriteLog(@"[CCUIModuleInstance Method Scanner]");
        CCWriteLog(@"==============================================");

        if (!cls) {
            CCWriteLog(@"CCUIModuleInstance NOT FOUND");
            return;
        }

        unsigned int count = 0;
        Method *methods = class_copyMethodList(cls, &count);

        for (unsigned int i = 0; i < count; i++) {
            SEL sel = method_getName(methods[i]);
            const char *types = method_getTypeEncoding(methods[i]);

            CCWriteLog([NSString stringWithFormat:
                @"  %@ | types=%s",
                NSStringFromSelector(sel),
                types ?: "(null)"]);
        }

        free(methods);

        CCWriteLog(@"==============================================");
        CCWriteLog([NSString stringWithFormat:
            @"[Finished] methods=%u",
            count]);
        CCWriteLog(@"==============================================");
    });
}