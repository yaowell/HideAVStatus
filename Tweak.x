#import <UIKit/UIKit.h>
#import <os/log.h>

%hook CCUILayoutView

- (void)layoutSubviews {
    %orig;
    
    // 获取真正的 layoutSource 代理对象类名
    id source = [self layoutSource];
    if (source) {
        os_log(OS_LOG_DEFAULT, "===[CC_DEBUG] layoutSource Class: %{public}s", object_getClassName(source));
    }
}

%end
