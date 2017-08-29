[English](./CHANGELOG.md) | 简体中文

#### Flyme 6.7.8.25 (2017-08-30)

- 【修复】修复完整包需要删除或者移动某些文件的情况下生成的 `ota` 差分包有异常的问题（The issue of Android Open Source Project）。


#### Flyme 6.7.7.14 (2017-07-18)

- 【修复】修改 `mac_permissions.xml` 的注入策略，签名标签由替换改为追加，修复由于签名标签重复导致 `sepolicy` 验证不通过的问题。


#### Flyme 6.7.6.30 (2017-07-04)

- 【修复】修复由于 `sepolicy` 的权限规则缺失，导致图库设置锁屏壁纸无效的问题（感谢 `Art_Chen琛琛` 的反馈）。
- 【修复】在 `sepolicy` 中注入缺失的其他权限规则。


#### Flyme 6.7.6.13 (2017-06-13)

- 【修复】更新 `apktool` 到版本 `v2.2.2` 后安装资源文件的位置发生错误的问题。


#### Flyme 6.7.6.5 (2017-06-06)

- 【修复】`Android Marshmallow` 引入 `Whitelist` 机制后不能打开 `flyme-res.apk` 对应的 `zygote` 的问题。


#### Flyme 6.7.5.19 (2017-05-23)

- 【修复】差分包的刷机脚本中无法删除多余文件夹的问题。


#### Flyme 6.7.5.15 (2017-05-16)

- 【修复】修复 `filesystem_config.txt` 配置文件中部分系统文件的权限获取错误的问题，可以通过命令 `make update_file_system_config` 更新 `filesystem_config.txt` 配置文件中的文件权限（感谢 `SY` 的反馈）。
- 【新增】支持在 `sepolicy` 中注入新的权限规则。根据机型的需要，可以在机型目录使用 `custom_sepolicy` 脚本自行定制需要注入的权限规则。根据机型的需要，可以在 `Makefile` 文件中自行配置是否注入 `sepolicy` 新的权限规则。


#### Flyme 6.7.5.8 (2017-05-09)

- 【修复】修复连接设置 APP 没有更新资源 ID 而引起的问题。
- 【修复】修复国际版本编译产出包的包名版本号错误的问题。


#### Flyme 6.7.5.2 (2017-05-02)

- 初始发布。
- 【新增】支持 `Android Marshmallow`（6.0.1）。
- 【新增】适配 Flyme 6。
