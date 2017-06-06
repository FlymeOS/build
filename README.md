English | [简体中文](./README_CN.md)

### build Introduction

 * envsetup.sh
   Execute `source build/envsetup.sh` for initialization environment

 * Flyme system boot/shutdown animation, in the implementation of the `make fullota` will be
   Based on the `RESOLUTION` parameters of the corresponding copy of the animation to the OTA package

 * compatibility
   Compatibility files, files that may be used to replace the OTA package.

 * configs
   Compiler configuration file, according to the configuration of the OTA package.

 * lib/dvm
   `dexopt` dependent, currently using ART mode, the module has been abandoned.

 * security
   Android signature file for apk signature.

 * sepolicy
   `seLinux` relevant.

 * target_files_template
   target_files template file.

 * tools
   Compile lock dependent tool script, part of the tool comes from the corresponding version of the AOSP product.

### Changelog

[CHANGELOG.md](./CHANGELOG.md)

