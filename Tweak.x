#import <UIKit/UIKit.h>

%hook CCUIModuleCollectionViewController

// 1. 拦截模块 Identifier 数组：遇到音视频/传感器模块直接剔除
- (void)setModuleIdentifiers:(NSArray *)identifiers {
    NSMutableArray *filtered = [NSMutableArray array];
    for (NSString *identifier in identifiers) {
        if (![identifier containsString:@"AudioConference"] && 
            ![identifier containsString:@"VideoConference"] && 
            ![identifier containsString:@"Sensor"] &&
            ![identifier containsString:@"ReplayKit"] &&
            ![identifier containsString:@"Topmost"]) {
            [filtered addObject:identifier];
        }
    }
    %orig([filtered copy]);
}

// 2. 拦截单个模块注入
- (void)addModuleWithIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"AudioConference"] || 
        [identifier containsString:@"VideoConference"] || 
        [identifier containsString:@"Sensor"] ||
        [identifier containsString:@"ReplayKit"] ||
        [identifier containsString:@"Topmost"]) {
        return; // 直接拦截，拒绝加载
    }
    %orig;
}

%end
