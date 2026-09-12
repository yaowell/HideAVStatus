#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

typedef struct {
    NSUInteger width;
    NSUInteger height;
} CCUILayoutSize;

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

        return NSStringFromClass([module class]) ?: @"<unknown>";
    } @catch (NSException *exception) {
        return @"<exception>";
    }
}

static NSArray *FilterRPCCModules(NSArray *original) {
    if (![original isKindOfClass:[NSArray class]]) {
        return original;
    }

    NSLog(@"==============================");
    NSLog(@"RPCC PROBE moduleInstances count=%lu",
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

        NSLog(@"[%lu] instance=%@ | module=%@ | Audio=%@ | Video=%@",
              (unsigned long)i,
              instanceClass,
              moduleClass,
              isAudio ? @"YES" : @"NO",
              isVideo ? @"YES" : @"NO");
    }

    NSLog(@"RPCC PROBE result: Audio=%lu | Video=%lu",
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

    NSLog(@"RPCC PROBE filtered count=%lu",
          (unsigned long)filtered.count);
    NSLog(@"==============================");

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