#import <UIKit/UIKit.h>

// 辅助函数：从任意模块实例中安全地取出标识符
static NSString *identifierForInstance(id instance) {
    NSString *identifier = nil;
    
    @try {
        identifier = [instance valueForKey:@"moduleIdentifier"];
        if (!identifier) identifier = [instance valueForKey:@"identifier"];
        if (!identifier) identifier = [[instance valueForKey:@"moduleRepresentation"] valueForKey:@"identifier"];
    } @catch (NSException *exception) {
        // 某些版本可能没有这些 key，忽略
    }
    
    return identifier ?: @"";
}

// 过滤模块实例，从源头移除这两个模块
%hook CCUIModuleInstanceManager

- (NSArray *)moduleInstances {
    NSArray *original = %orig;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:original.count];
    
    for (id instance in original) {
        NSString *identifier = identifierForInstance(instance);
        if ([identifier containsString:@"RPCCAudio"] || [identifier containsString:@"RPCCVideo"]) {
            continue;
        }
        [filtered addObject:instance];
    }
    return filtered;
}

- (NSArray *)enabledModuleInstances {
    NSArray *original = %orig;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:original.count];
    
    for (id instance in original) {
        NSString *identifier = identifierForInstance(instance);
        if ([identifier containsString:@"RPCCAudio"] || [identifier containsString:@"RPCCVideo"]) {
            continue;
        }
        [filtered addObject:instance];
    }
    return filtered;
}

%end

// 可选：如果你觉得上面的方法在你的 iOS 版本上没生效，可以改为直接禁用模块实例
/*
%hook CCUIModuleInstance

- (BOOL)isEnabled {
    NSString *identifier = identifierForInstance(self);
    if ([identifier containsString:@"RPCCAudio"] || [identifier containsString:@"RPCCVideo"]) {
        return NO;
    }
    return %orig;
}

- (BOOL)enabled {
    NSString *identifier = identifierForInstance(self);
    if ([identifier containsString:@"RPCCAudio"] || [identifier containsString:@"RPCCVideo"]) {
        return NO;
    }
    return %orig;
}

%end
*/

// ========== 可选调试代码：打印当前所有模块标识符 ==========
// 取消注释下面的代码，在第一次打开控制中心时会在控制台输出
// 所有真实的模块 identifier，然后你就能准确判断需要过滤哪些字符串。

/*
%hook CCUIModuleInstanceManager

- (void)loadModules {
    %orig;
    NSArray *instances = [self valueForKey:@"moduleInstances"];
    for (id instance in instances) {
        NSLog(@"[Tweak] CC Module: %@ -> %@",
              identifierForInstance(instance),
              [instance valueForKey:@"contentViewController"]);
    }
}

%end
*/