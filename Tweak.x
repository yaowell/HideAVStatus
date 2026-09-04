#import <UIKit/UIKit.h>

@interface CCUIModuleCollectionViewController : UIViewController
@property (nonatomic, copy) NSArray *moduleIdentifiers;
@end

static BOOL isTargetModule(NSString *identifier) {
    if (!identifier) return NO;
    return [identifier containsString:@"AudioConferenceControlCenter"] ||
           [identifier containsString:@"VideoConferenceControlCenter"];
}

%hook CCUIModuleCollectionViewController

// 拦截 Setter 方法：当系统传入模块列表时，直接过滤掉录音/视频模块
- (void)setModuleIdentifiers:(NSArray *)moduleIdentifiers {
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *identifier in moduleIdentifiers) {
        if (!isTargetModule(identifier)) {
            [filtered addObject:identifier];
        }
    }
    %orig([filtered copy]);
}

// 拦截 Getter 方法兜底
- (NSArray *)moduleIdentifiers {
    NSArray *orig = %orig;
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *identifier in orig) {
        if (!isTargetModule(identifier)) {
            [filtered addObject:identifier];
        }
    }
    return [filtered copy];
}

%end
