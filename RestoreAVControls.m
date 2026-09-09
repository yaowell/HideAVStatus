#import <Foundation/Foundation.h>

static NSString * const kAudioModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.AudioConferenceControlCenterModule.plist";

static NSString * const kVideoModule =
    @"/var/Managed Preferences/mobile/com.apple.replaykit.VideoConferenceControlCenterModule.plist";

// 备份目录
static NSString * const kBackupDir =
    @"/var/mobile/Library/HideAVControlsBackup";

// 备份文件
static NSString * const kAudioBackup =
    @"/var/mobile/Library/HideAVControlsBackup/AudioConferenceControlCenterModule.plist";

static NSString * const kVideoBackup =
    @"/var/mobile/Library/HideAVControlsBackup/VideoConferenceControlCenterModule.plist";

// “安装前不存在”的标记
static NSString * const kAudioAbsent =
    @"/var/mobile/Library/HideAVControlsBackup/AudioConferenceControlCenterModule.absent";

static NSString * const kVideoAbsent =
    @"/var/mobile/Library/HideAVControlsBackup/VideoConferenceControlCenterModule.absent";


static void RestoreModule(NSString *path,
                          NSString *backupPath,
                          NSString *absentMarker)
{
    NSFileManager *fm = [NSFileManager defaultManager];

    // 情况 1：
    // 安装前存在原始 plist，现在用备份原样恢复
    if ([fm fileExistsAtPath:backupPath]) {

        // 如果当前插件产生的文件存在，先删除
        if ([fm fileExistsAtPath:path]) {
            [fm removeItemAtPath:path error:nil];
        }

        NSError *error = nil;

        BOOL restored =
            [fm copyItemAtPath:backupPath
                        toPath:path
                         error:&error];

        if (!restored) {
            NSLog(@"[HideAVControlsRestore] RESTORE FAILED: %@ error=%@",
                  path,
                  error);
            return;
        }

        NSLog(@"[HideAVControlsRestore] ORIGINAL RESTORED: %@",
              path);

        // 恢复成功后删除备份
        [fm removeItemAtPath:backupPath error:nil];

        return;
    }

    // 情况 2：
    // 安装前原本不存在这个 plist
    // 因此卸载时必须把插件产生的 plist 删除
    if ([fm fileExistsAtPath:absentMarker]) {

        if ([fm fileExistsAtPath:path]) {

            NSError *error = nil;

            BOOL removed =
                [fm removeItemAtPath:path
                               error:&error];

            if (!removed) {
                NSLog(@"[HideAVControlsRestore] DELETE FAILED: %@ error=%@",
                      path,
                      error);
                return;
            }

            NSLog(@"[HideAVControlsRestore] ORIGINAL WAS ABSENT, DELETED: %@",
                  path);
        }

        // 删除标记
        [fm removeItemAtPath:absentMarker error:nil];

        return;
    }

    // 没找到备份，也没找到“不存在”标记
    // 为安全起见，不擅自修改系统文件
    NSLog(@"[HideAVControlsRestore] NO BACKUP STATE, SKIP: %@",
          path);
}


int main(int argc, char *argv[])
{
    @autoreleasepool {

        RestoreModule(kAudioModule,
                      kAudioBackup,
                      kAudioAbsent);

        RestoreModule(kVideoModule,
                      kVideoBackup,
                      kVideoAbsent);
    }

    return 0;
}