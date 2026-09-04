#import <UIKit/UIKit.h>
#include <sys/time.h>

// 1. 直接写文件（完全不依赖 NSLog）
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
    
    // 加个时间戳
    struct timeval tv;
    gettimeofday(&tv, NULL);
    NSString *line = [NSString stringWithFormat:@"[%ld.%03d] %@\n", (long)tv.tv_sec, tv.tv_usec/1000, msg];
    [fh writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
    [fh closeFile];
}

// 2. 辅助：安全获取模块标识符
static NSString *identifierForInstance(id instance) {
    NSString *identifier = nil;
    @try {
        identifier = [instance valueForKey:@"moduleIdentifier"];
        if (!identifier) identifier = [instance valueForKey:@"identifier"];
        if (!identifier) identifier = [[instance valueForKey:@"moduleRepresentation"] valueForKey:@"identifier"];
    } @catch (NSException *exception) {}
    return identifier ?: @"Unknown";
}

// 3. 过滤判断（先用宽泛的关键词，拿到日志后再精确修改）
static BOOL shouldFilterIdentifier(NSString *identifier) {
    if (!identifier) return NO;
    // 先尝试过滤包含 RPCC、Audio、Video 的模块
    return [identifier containsString:@"RPCC"] || 
           [identifier containsString:@"Audio"] || 
           [identifier containsString:@"Video"];
}

// ========================================
// Hook CCUIModuleInstanceManager
// ========================================
%hook CCUIModuleInstanceManager

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
// Hook CCUIModuleInstance (备选)
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

%end

// ========================================
// Hook CCUIModuleCollectionViewController (兜底)
// ========================================
%hook CCUIModuleCollectionViewController

- (void)_updateEnabledModuleIdentifiers {
    %orig;
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
// Hook CCUILayoutView (布局层兜底)
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
