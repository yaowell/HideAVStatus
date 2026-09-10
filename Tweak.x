#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSString *const kLogFilePath = @"/var/mobile/Documents/CC_Probe.log";

static NSMutableSet *gRecordedEntries = nil;
static dispatch_queue_t gLogQueue = nil;

static void BMLog(NSString *message)
{
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        gRecordedEntries = [NSMutableSet set];
        gLogQueue = dispatch_queue_create("com.yaowell.hideavcontrols.probe", DISPATCH_QUEUE_SERIAL);

        [[NSFileManager defaultManager] removeItemAtPath:kLogFilePath error:nil];
    });

    if (!message) {
        return;
    }

    dispatch_async(gLogQueue, ^{
        if ([gRecordedEntries containsObject:message]) {
            return;
        }

        [gRecordedEntries addObject:message];

        NSFileManager *fm = [NSFileManager defaultManager];

        if (![fm fileExistsAtPath:kLogFilePath]) {
            [fm createFileAtPath:kLogFilePath contents:nil attributes:nil];
        }

        NSFileHandle *handle =
            [NSFileHandle fileHandleForWritingAtPath:kLogFilePath];

        if (!handle) {
            return;
        }

        [handle seekToEndOfFile];

        NSString *line =
            [NSString stringWithFormat:@"%@\n", message];

        [handle writeData:
            [line dataUsingEncoding:NSUTF8StringEncoding]];

        [handle closeFile];
    });
}

static NSString *BMModuleIdentifier(id instance)
{
    if (!instance) {
        return @"<nil>";
    }

    NSString *identifier = nil;

    @try {
        if ([instance respondsToSelector:@selector(moduleIdentifier)]) {
            identifier = [instance performSelector:@selector(moduleIdentifier)];
        }
    }
    @catch (NSException *exception) {
        identifier = nil;
    }

    if (!identifier) {
        @try {
            identifier = [instance valueForKey:@"moduleIdentifier"];
        }
        @catch (NSException *exception) {
            identifier = nil;
        }
    }

    if (!identifier) {
        @try {
            identifier = [instance valueForKey:@"identifier"];
        }
        @catch (NSException *exception) {
            identifier = nil;
        }
    }

    return identifier ?: @"<Unknown>";
}

static BOOL BMClassNameMatches(NSString *className)
{
    if (!className) {
        return NO;
    }

    if ([className hasPrefix:@"CCUI"]) {
        return YES;
    }

    NSArray *keywords = @[
        @"Module",
        @"Layout",
        @"Grid",
        @"Collection",
        @"Content"
    ];

    for (NSString *keyword in keywords) {
        if ([className containsString:keyword] &&
            [className containsString:@"CC"]) {
            return YES;
        }
    }

    return NO;
}

static BOOL BMSelectorMatches(NSString *selectorName)
{
    if (!selectorName) {
        return NO;
    }

    NSString *lower =
        selectorName.lowercaseString;

    NSArray *keywords = @[
        @"layout",
        @"layoutsubviews",
        @"size",
        @"frame",
        @"height",
        @"width",
        @"content",
        @"module",
        @"margin",
        @"padding",
        @"inset"
    ];

    for (NSString *keyword in keywords) {
        if ([lower containsString:keyword]) {
            return YES;
        }
    }

    return NO;
}

static void BMScanRuntime(void)
{
    BMLog(@"");
    BMLog(@"==================================================");
    BMLog(@"[Runtime Scan] START");
    BMLog(@"==================================================");

    int classCount =
        objc_getClassList(NULL, 0);

    if (classCount <= 0) {
        BMLog(@"[Runtime Scan] objc_getClassList returned 0");
        return;
    }

    Class *classes =
        (Class *)malloc(sizeof(Class) * classCount);

    if (!classes) {
        BMLog(@"[Runtime Scan] malloc failed");
        return;
    }

    classCount =
        objc_getClassList(classes, classCount);

    BMLog([NSString stringWithFormat:
           @"[Runtime Scan] Loaded classes: %d",
           classCount]);

    int matchedClassCount = 0;

    for (int i = 0; i < classCount; i++) {

        Class cls = classes[i];

        if (!cls) {
            continue;
        }

        NSString *className =
            NSStringFromClass(cls);

        if (!BMClassNameMatches(className)) {
            continue;
        }

        unsigned int methodCount = 0;

        Method *methods =
            class_copyMethodList(cls, &methodCount);

        if (!methods) {
            continue;
        }

        NSMutableArray *matchedSelectors =
            [NSMutableArray array];

        for (unsigned int j = 0;
             j < methodCount;
             j++) {

            SEL selector =
                method_getName(methods[j]);

            if (!selector) {
                continue;
            }

            NSString *selectorName =
                NSStringFromSelector(selector);

            if (BMSelectorMatches(selectorName)) {

                if (![matchedSelectors
                      containsObject:selectorName]) {

                    [matchedSelectors
                        addObject:selectorName];
                }
            }
        }

        free(methods);

        if (matchedSelectors.count == 0) {
            continue;
        }

        matchedClassCount++;

        [matchedSelectors
            sortUsingSelector:@selector(compare:)];

        NSString *line =
            [NSString stringWithFormat:
             @"[Class] %@ | Methods: %@",
             className,
             [matchedSelectors
                 componentsJoinedByString:@", "]];

        BMLog(line);
    }

    free(classes);

    BMLog([NSString stringWithFormat:
           @"[Runtime Scan] Matched classes: %d",
           matchedClassCount]);

    BMLog(@"==================================================");
    BMLog(@"[Runtime Scan] END");
    BMLog(@"==================================================");
}

%hook CCUIModuleInstanceManager

- (NSArray *)enabledModuleInstances
{
    NSArray *instances = %orig;

    static dispatch_once_t probeOnce;

    dispatch_once(&probeOnce, ^{

        BMLog(@"");
        BMLog(@"##################################################");
        BMLog(@"[Probe] CCUIModuleInstanceManager detected");
        BMLog(@"[Probe] enabledModuleInstances called");
        BMLog(@"##################################################");

        BMLog([NSString stringWithFormat:
               @"[Probe] Instance count: %lu",
               (unsigned long)instances.count]);

        NSUInteger index = 0;

       ​⬤