#import <UIKit/UIKit.h>

// ========================================
// 工具函数
// ========================================

// 写日志到 /var/mobile/Documents/ccdebug.log
static void WriteDebug(NSString *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:args];
    va_end(args);
    
    NSString *path = @"/var/mobile/Documents/ccdebug.log";
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        [fm createFileAtPath:path contents:nil attributes:nil];
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    [fh seekToEndOfFile];
    NSString *line = [NSString stringWithFormat:@"%@\n", msg];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

// 从任意模块实例中取 identifier
static NSString *identifierForInstance(id instance) {
    NSString *identifier = nil;
    @try {
        identifier = [instance valueForKey:@"moduleIdentifier"];
        if (identifier.length == 0) identifier = [instance valueForKey:@"identifier"];
        if (identifier.length == 0) identifier = [[instance valueForKey:@"moduleRepresentation"] valueForKey:@"identifier"];
    } @catch (NSException *e) {}
    return identifier ?: @"";
}

// 判断是否为需要屏蔽的模块
static BOOL shouldFilterIdentifier(NSString *identifier) {
    if (identifier.length == 0) return NO;
    // 如果下面列表没命中，可以稍后根据日志文件里的内容修改这串字符
    return [identifier containsString:@"RPCCAudio"] ||
           [identifier containsString:@"RPCCVideo"] ||
           [identifier containsString:@"rpcc-audio"] ||
           [identifier containsString:@"rpcc-video"] ||
           [identifier containsString:@"audio-call-effects"] ||
           [identifier containsString:@"video-call-effects"];
}

// ========================================
// 1. 过滤 moduleManager 中的模块实例（最核心）
// ========================================
%hook CCUIModuleInstanceManager

// 打印所有现有的模块，方便确认真实 identifier
- (void)loadModules {
    %orig;
    NSArray *instances = [self valueForKey:@"moduleInstances"] ?: @[];
    for (id instance in instances) {
        NSString *identifier = identifierForInstance(instance);
        id vc = [instance valueForKey:@"contentViewController"];
        WriteDebug(@"[CCDebug] Module: %@ | vc = %@", identifier,
                   vc ? NSStringFromClass([vc class]) : @"nil");
    }
}

- (NSArray *)moduleInstances {
    NSArray *original = %orig;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:original.count];
    for (id instance in original) {
        NSString *identifier = identifierForInstance(instance);
        if (shouldFilterIdentifier(identifier)) {
            WriteDebug(@"[CCDebug] 已过滤 moduleInstances: %@", identifier);
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
        if (shouldFilterIdentifier(identifier)) {
            WriteDebug(@"[CCDebug] 已过滤 enabledModuleInstances: %@", identifier);
            continue;
        }
        [filtered addObject:instance];
    }
    return filtered;
}

%end

// ========================================
// 2. 禁用模块实例（备选）
// ========================================
%hook CCUIModuleInstance

- (BOOL)isEnabled {
    NSString *identifier = identifierForInstance(self);
    if (shouldFilterIdentifier(identifier)) {
        WriteDebug(@"[CCDebug] 已禁用 isEnabled: %@", identifier);
        return NO;
    }
    return %orig;
}

- (BOOL)enabled {
    NSString *identifier = identifierForInstance(self);
    if (shouldFilterIdentifier(identifier)) {
        WriteDebug(@"[CCDebug] 已禁用 enabled: %@", identifier);
        return NO;
    }
    return %orig;
}

%end

// ========================================
// 3. 集合视图层面：移除已加载的子控制器（兜底）
// ========================================
%hook CCUIModuleCollectionViewController

- (void)_updateEnabledModuleIdentifiers {
    %orig;
    // 移除已被添加的 RPCC 子控制器
    NSArray *children = [self.childViewControllers copy];
    for (UIViewController *child in children) {
        NSString *cls = NSStringFromClass([child class]);
        if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
            [child.view removeFromSuperview];
            [child removeFromParentViewController];
            WriteDebug(@"[CCDebug] 已移除子控制器: %@", cls);
        }
    }
}

%end

// ========================================
// 4. 布局层兜底：直接把这些模块的 view 设为零尺寸
// ========================================
%hook CCUILayoutView

- (void)layoutSubviews {
    %orig;
    for (UIView *sub in self.subviews) {
        NSString *cls = NSStringFromClass([sub class]);
        if ([cls containsString:@"RPCCAudio"] || [cls containsString:@"RPCCVideo"]) {
            sub.frame = CGRectZero;
            sub.hidden = YES;
            WriteDebug(@"[CCDebug] 布局层已隐藏: %@", cls);
        }
    }
}

%end
