#import <UIKit/UIKit.h>

@interface CCUILayoutView : UIView
- (id)layoutSource;
@end

static void dumpViewHierarchy(UIView *view, NSMutableString *log, int depth) {
    if (!view) return;
    
    // 缩进表示层级
    NSMutableString *indent = [NSMutableString string];
    for (int i = 0; i < depth; i++) {
        [indent appendString:@"  "];
    }
    
    NSString *clsName = NSStringFromClass([view class]);
    CGRect frame = view.frame;
    
    // 记录 View 类名和 Frame
    [log appendFormat:@"%@|- [%@] frame: (%.1f, %.1f, %.1f, %.1f) hidden: %d\n", 
        indent, clsName, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height, view.hidden];
    
    // 递归遍历所有子视图
    for (UIView *subview in view.subviews) {
        dumpViewHierarchy(subview, log, depth + 1);
    }
}

%hook CCUILayoutView

- (void)layoutSubviews {
    %orig;
    
    NSMutableString *logContent = [NSMutableString string];
    [logContent appendString:@"\n========== CCUILayoutView Hierarchy Start ==========\n"];
    
    // 递归打印当前 CollectionView 的整个视图树
    dumpViewHierarchy(self, logContent, 0);
    
    [logContent appendString:@"========== CCUILayoutView Hierarchy End ==========\n"];
    
    // 写入本地文件
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/cc_debug.txt"];
    if (fileHandle) {
        [fileHandle seekToEndOfFile];
        [fileHandle writeData:[logContent dataUsingEncoding:NSUTF8StringEncoding]];
        [fileHandle closeFile];
    } else {
        [logContent writeToFile:@"/tmp/cc_debug.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
}

%end
