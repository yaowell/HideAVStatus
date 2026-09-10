#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogPath = @"/var/mobile/Documents/RPCC_ModuleMethods.log";

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

static void ScanClass(Class cls) {
    if (!cls) return;

    CCWriteLog(@"----------------------------------------------");
    CCWriteLog([NSString stringWithFormat:@"CLASS: %@", NSStringFromClass(cls)]);
    CCWriteLog(@"----------------------------------------------");

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

    CCWriteLog([NSString stringWithFormat:
        @"[Finished] methods=%u", count]);
}

%hook CCUIModuleInstance

- (id)module {
    id result = %orig;

    @try {
        Class cls = result ? [result class] : Nil;

        if (cls) {
            NSString *name = NSStringFromClass(cls);

            if ([name isEqualToString:@"RPCCAudioSettingsModule"] ||
                [name isEqualToString:@"RPCCVideoSettingsModule"]) {

                static NSMutableSet *scannedClasses;
                static dispatch_once_t onceToken;

                dispatch_once(&onceToken, ^{
                    scannedClasses = [NSMutableSet set];
                });

                @synchronized (scannedClasses) {
                    if (![scannedClasses containsObject:name]) {
                        [scannedClasses addObject:name];

                        CCWriteLog(@"==============================================");
                        CCWriteLog([NSString stringWithFormat:
                            @"[DYNAMIC CLASS FOUND] %@", name]);

                        ScanClass(cls);

                        CCWriteLog(@"==============================================");
                    }
                }
            }
        }

    } @catch (NSException *exception) {
        CCWriteLog([NSString stringWithFormat:
            @"[EXCEPTION] %@", exception]);
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
        CCWriteLog(@"[RPCC Dynamic Module Method Scanner]");
        CCWriteLog(@"Waiting for RPCCAudio/RPCCVideo...");
        CCWriteLog(@"==============================================");
    });
}