#import <UIKit/UIKit.h>

@interface CCUILayoutView : UIView
- (id)layoutSource;
@end

%hook CCUILayoutView

- (void)layoutSubviews {
    %orig;
    
    id source = [self layoutSource];
    if (source) {
        NSString *className = [NSString stringWithUTF8String:object_getClassName(source)];
        NSString *logContent = [NSString stringWithFormat:@"layoutSource Class: %@\n", className];
        
        // 写入本地文件 /tmp/cc_debug.txt
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:@"/tmp/cc_debug.txt"];
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[logContent dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        } else {
            [logContent writeToFile:@"/tmp/cc_debug.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
    }
}

%end
