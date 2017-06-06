[English](./CHANGELOG.md) | 简体中文


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
