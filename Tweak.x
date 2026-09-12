#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

static void RPCCWriteLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *text = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);

    NSString *path = @"/var/mobile/Documents/RPCCProbe.log";

    @try {
        NSString *line = [text stringByAppendingString:@"\n"];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
            return;
        }

        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:path];

        if (!handle) return;

        [handle seekToEndOfFile];
        [handle writeData:data];
        [handle closeFile];
    } @catch (NSException *exception) {
    }
}

static BOOL IsRPCCModule(id instance) {
    if (!instance) return NO;

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
        );

        if (!module) return NO;

        NSString *name = NSStringFromClass([module class]);

        return [name isEqualToString:@"RPCCAudioSettingsModule"] ||
               [name isEqualToString:@"RPCCVideoSettingsModule"];
    } @catch (NSException *exception) {
        return NO;
    }
}

static NSString *RPCCModuleClassName(id instance) {
    if (!instance) return @"<nil>";

    @try {
        id module = ((id (*)(id, SEL))objc_msgSend)(
            instance,
            sel_registerName("module")
        );

        if (!module) return @"<nil-module>";

        NSString *name = NSStringFromClass([module class]);
        return name ?: @"<unknown>";
    } @catch (NSException *exception) {
        return @"<exception>";
    }
}

static NSArray *FilterRPCCModules(NSArray *original) {
    if (![original isKindOfClass:[NSArray class]]) {
        return original;
    }

    RPCCWriteLog(@"==============================");
    RPCCWriteLog(@"RPCC PROBE count=%lu",
                 (unsigned long)original.count);

    NSUInteger audioCount = 0;
    NSUInteger videoCount = 0;

    for (NSUInteger i = 0; i < original.count; i++) {
        id instance = original[i];

        NSString *instanceClass =
            instance ? NSStringFromClass([instance class]) : @"<nil>";

        NSString *moduleClass =
            RPCCModuleClassName(instance);

        BOOL isAudio =
            [moduleClass isEqualToString:@"RPCCAudioSettingsModule"];

        BOOL isVideo =
            [moduleClass isEqualToString:@"RPCCVideoSettingsModule"];

        if (isAudio) audioCount++;
        if (isVideo) videoCount++;

        RPCCWriteLog(@"[%lu] instance=%@ | module=%@ | Audio=%@ | Video=%@",
                     (unsigned long)i,
                     instanceClass,
                     moduleClass,
                     isAudio ? @"YES" : @"NO",
                     isVideo ? @"YES" : @"NO");
    }

    RPCCWriteLog(@"RESULT Audio=%lu | Video=%lu",
                 (unsigned long)audioCount,
                 (unsigned long)videoCount);

    NSMutableArray *filtered =
        [NSMutableArray arrayWithCapacity:original.count];

    for (id instance in original) {
        if (IsRPCCModule(instance)) {
            continue;
        }

        [filtered addObject:instance];
    }

    RPCCWriteLog(@"filtered count=%lu",
                 (unsigned long)filtered.count);
    RPCCWriteLog(@"==============================");

    return filtered;
}

%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *original = %orig;
    return FilterRPCCModules(original);
}

- (NSArray *)enabledModuleInstances {
    NSArray *original = %orig;
    return FilterRPCCModules(original);
}

%end

%hook CCUIModuleInstance

- (CCUILayoutSize)prototypeModuleSize {
    if (IsRPCCModule(self)) {
        CCUILayoutSize zeroSize;
        zeroSize.width = 0;
        zeroSize.height = 0;
        return zeroSize;
    }

    return %orig;
}

%end