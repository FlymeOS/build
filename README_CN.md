[English](./README.md) | 简体中文

### build 介绍

 * envsetup.sh
   执行`source build/envsetup.sh`用于初始化环境

 * bootanimations
   Flyme 系统的开关机动画,在执行`make fullota`的时候会根据机型的`RESOLUTION`参数拷贝对应的动画到ota包中.

 * compatibility
   兼容性文件,存放可能用于替换到ota包中的文件.

 * configs
   编译配置文件,根据配置组合生成ota包.

 * lib/dvm
   `dexopt`依赖,目前已经使用ART模式,该模块已废弃.

 * security
   安卓签名文件,用于apk签名.

 * sepolicy
   seLinux相关.

 * target_files_template
   target_files模板文件.

 * tools
   编译锁依赖的工具脚本,部分工具来自与对应安卓版本的AOSP产物.

### 更新记录

[CHANGELOG_CN.md](./CHANGELOG_CN.md)

