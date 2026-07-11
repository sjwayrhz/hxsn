禁止系统更新，搜到的教程如下：

先看你输出里关键两个更新相关包：
1. `com.oneplus.opbackup` 系统OTA更新（核心）
2. `com.oneplus.appupgrader` 应用升级

你现在确实是**氢OS**，直接用这套ADB禁用命令即可：
```bash
# 禁用系统OTA更新主程序
adb shell pm disable-user --user 0 com.oneplus.opbackup
# 清除更新缓存，删掉已有更新包/通知
adb shell pm clear --user 0 com.oneplus.opbackup
# 禁用应用商店自动升级
adb shell pm disable-user --user 0 com.oneplus.appupgrader
# 禁用底层动态系统更新服务（辅助防更新）
adb shell pm disable-user --user 0 com.android.dynsystem
```

### 验证是否禁用成功
```bash
adb shell pm list packages -d | grep opbackup
```
有输出就代表已禁用；无输出说明没生效，重新执行一遍禁用命令。

### 以后想恢复更新
```bash
adb shell pm enable --user 0 com.oneplus.opbackup
adb shell pm enable --user 0 com.oneplus.appupgrader
adb shell pm enable --user 0 com.android.dynsystem
```

### 实际操作
```
mint@mint-pc:~$ adb shell pm list packages -d | grep opbackup
mint@mint-pc:~$ adb shell pm disable-user --user 0 com.oneplus.opbackup
Package com.oneplus.opbackup new state: disabled-user
mint@mint-pc:~$ adb shell pm clear --user 0 com.oneplus.opbackup
Success
mint@mint-pc:~$ adb shell pm disable-user --user 0 com.oneplus.appupgrader
Package com.oneplus.appupgrader new state: disabled-user
mint@mint-pc:~$ adb shell pm disable-user --user 0 com.android.dynsystem
Package com.android.dynsystem new state: disabled-user
mint@mint-pc:~$ adb shell pm list packages -d | grep opbackup
package:com.oneplus.opbackup
mint@mint-pc:~$ 
```
