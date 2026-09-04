#import <UIKit/UIKit.h>

// 1. 拦截控制中心模块配置中心：直接从源头把这两个模块从列表中剔除
%hook CCUIModuleSettingsManager

- (id)moduleSettingsForModuleIdentifier:(NSString *)identifier {
    // 如果系统尝试获取音视频模块的布局设置，直接返回 nil，让布局引擎彻底忽略它们
    if ([identifier containsString:@"audio-attribution"] || 
        [identifier containsString:@"video-attribution"] ||
        [identifier containsString:@"RPCCAudio"] || 
        [identifier containsString:@"RPCCVideo"]) {
        return nil;
    }
    return %orig;
}

%end

// 2. 拦截 Module Layout 矩阵生成：强行清空它们占用的 Grid 布局
%hook CCUIMGroupLayoutGrid

- (id)ccui_componentForModuleIdentifier:(NSString *)identifier {
    if ([identifier containsString:@"audio-attribution"] || 
        [identifier containsString:@"video-attribution"] ||
        [identifier containsString:@"RPCCAudio"] || 
        [identifier containsString:@"RPCCVideo"]) {
        return nil; // 布局网格不为它分配任何坐标
    }
    return %orig;
}

%end
