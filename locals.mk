#
# locals.mk
# owner: coron
# 

# set PRJ_ROOT to PWD
PRJ_ROOT := $(PWD)

# if doesn't set PRJ_NAME, set by PRJ_ROOT
ifeq ($(strip $(PRJ_NAME)),)
    PRJ_NAME := $(shell basename $(PRJ_ROOT))
endif

PROJECT_NAME_UP := $(strip $(shell echo $(PRJ_NAME) | tr '[a-z]' '[A-Z]'))

# if doesn't set, set to $(PRJ_ROOT)/logo.bin
# which means where the logo.bin is, only for mtk
# if the file $(PRJ_LOGO_BIN) doesn't exist, ignore
ifeq ($(strip $(PRJ_LOGO_BIN)),)
    PRJ_LOGO_BIN := $(PRJ_ROOT)/logo.bin
endif

ifeq ($(strip $(ANDROID_SDK_VERSION)),)
    ANDROID_SDK_VERSION := 15
endif

ROMER := $(strip $(patsubst ro.flyme.romer=%,%,$(filter ro.flyme.romer=%,$(override_property))))

# the version of the target
# which would be set to build.prop by $(MAKE_BUILD_PROP)
# eg:
#	make xxx version = 
ifneq ($(strip $(version)),)
VERSION_NUMBER := $(version)
else
VERSION_NUMBER :=
endif #ifneq ($(strip $(version)),)

ifeq ($(strip $(SIGN_OTA)),)
SIGN_OTA := true
endif

ifeq ($(strip $(REDUCE_RESOURCES)),)
REDUCE_RESOURCES := false
endif

ifeq ($(strip $(PRODUCE_IMAGES_FOR_FASTBOOT)),)
PRODUCE_IMAGES_FOR_FASTBOOT := false
endif


##################### density ############################
ALL_DENSITY := \
     mdpi \
     hdpi \
     xhdpi \
     xxhdpi \
     xxxhdpi

ifeq ($(strip $(DENSITY)),)
    DENSITY := hdpi
endif

DENSITY := $(shell echo $(DENSITY) | tr A-Z a-z)

ifeq ($(filter $(DENSITY),$(ALL_DENSITY)),$(DENSITY))
    NOT_USED_DENSITY := $(filter-out $(DENSITY),$(ALL_DENSITY))
else
    $(error density must be one of: $(ALL_DENSITY), ignore case)
endif

PRODUCT_LOCALES += en_US,zh_CN

empty :=
space := $(empty) $(empty)
comma := $(empty),$(empty)

PRIVATE_PRODUCT_AAPT_CONFIG := $(subst $(space),$(comma),$(sort normal,$(PRODUCT_LOCALES)))
 
PRIVATE_PRODUCT_AAPT_PREF_CONFIG := $(DENSITY)

###################### Makefile ###########################
PRJ_MAKEFILE       := $(PRJ_ROOT)/Makefile

##################### board zip ###########################
BOARD_DIR          := $(PRJ_ROOT)/board
BOARD_ZIP          := $(BOARD_DIR)/board.zip
BOARD_LAST_ZIP     := $(BOARD_DIR)/last_board.zip

ifeq ($(strip $(THEME_RES)),)
ifneq ($(wildcard $(BOARD_DIR)/theme_full_res.zip),)
THEME_RES := $(BOARD_DIR)/theme_full_res.zip
endif
endif

##################### apktool tags ########################
# which used to compile multiple projects simultaneously
APKTOOL_BOARD_TAG  := board_$(PRJ_NAME)
APKTOOL_VENDOR_TAG := vendor_$(PRJ_NAME)
APKTOOL_MERGED_TAG := merged_$(PRJ_NAME)

APKTOOL_FRAME_PATH_BOARD_MODIFY := ~/apktool/framework/board_modify/

################## board's bootanimation ####################
BOARD_BOOTANIMATION  := $(PORT_ROOT)/build/bootanimations

######################## vendor ###########################
VENDOR_DIR := vendor

VENDOR_META           := $(VENDOR_DIR)/META
VENDOR_METAINF        := $(VENDOR_DIR)/METAINF
VENDOR_OTA            := $(VENDOR_DIR)/OTA
VENDOR_SYSTEM         := $(VENDOR_DIR)/system
VENDOR_FRAMEWORK      := $(VENDOR_SYSTEM)/framework
VENDOR_FRAMEWORK_RES  := $(VENDOR_SYSTEM)/framework/framework-res.apk

######################### history #########################
HISTORY_DIR := history_package

######################### out #############################
OUT_DIR := out

OUT_OBJ_DIR    := $(OUT_DIR)/obj
OUT_TARGET_DIR := $(OUT_DIR)/merged_target_files
OUT_LOGO_BIN   := $(OUT_DIR)/logo.bin

########################## obj ############################
OUT_OBJ_BOOT      := $(OUT_OBJ_DIR)/BOOT
OUT_OBJ_RECOVERY  := $(OUT_OBJ_DIR)/RECOVERY
OUT_OBJ_META      := $(OUT_OBJ_DIR)/META
OUT_OBJ_SYSTEM    := $(OUT_OBJ_DIR)/system
OUT_OBJ_FRAMEWORK := $(OUT_OBJ_SYSTEM)/framework
OUT_OBJ_APP       := $(OUT_OBJ_SYSTEM)/app
OUT_OBJ_RES       := $(OUT_OBJ_SYSTEM)/res
OUT_OBJ_BIN       := $(OUT_OBJ_SYSTEM)/bin

MERGE_NONE_TXT   := $(OUT_OBJ_RES)/merge_none.txt
MERGE_ADD_TXT    := $(OUT_OBJ_RES)/merge_add.txt
MERGE_UPDATE_TXT := $(OUT_OBJ_RES)/merge_update.txt

IF_BOARD_RES	:= $(OUT_OBJ_FRAMEWORK)/ifboard
IF_VENDOR_RES	:= $(OUT_OBJ_FRAMEWORK)/ifvendor
IF_MERGED_RES	:= $(OUT_OBJ_FRAMEWORK)/ifmerged
IF_ALL_RES	:= $(IF_BOARD_RES) $(IF_VENDOR_RES) $(IF_MERGED_RES)

FRW_RES_DECODE        := $(OUT_OBJ_RES)/frw_res_decode
FRW_RES_DECODE_MERGED := $(FRW_RES_DECODE)/merged
FRW_RES_DECODE_VENDOR := $(FRW_RES_DECODE)/vendor
FRW_RES_DECODE_BOARD  := $(FRW_RES_DECODE)/board
PREPARE_FRW_RES_JOB   := $(FRW_RES_DECODE)/done

BOARD_PUBLIC_XML  := $(FRW_RES_DECODE_BOARD)/framework-res/res/values/public.xml
VENDOR_PUBLIC_XML := $(FRW_RES_DECODE_VENDOR)/framework-res/res/values/public.xml
MERGED_PUBLIC_XML := $(FRW_RES_DECODE_MERGED)/framework-res/res/values/public.xml

OUT_OBJ_AUTOCOM       := $(OUT_OBJ_DIR)/autocom

AUTOCOM_BOARD         := $(OUT_OBJ_AUTOCOM)/board
AUTOCOM_PREPARE_BOARD := $(AUTOCOM_BOARD)/.prepareboard

AUTOCOM_VENDOR         := $(OUT_OBJ_AUTOCOM)/vendor
AUTOCOM_PREPARE_VENDOR := $(AUTOCOM_BOARD)/.preparevendor

AUTOCOM_MERGED         := $(OUT_OBJ_AUTOCOM)/merged
AUTOCOM_PREPARE_MERGED := $(AUTOCOM_BOARD)/.preparemerged

AUTOCOM_PRECONDITION   := $(AUTOCOM_BOARD)/.autocom_precondition

####################### auto fix ##########################
AUTOFIX                 := $(OUT_OBJ_DIR)/autofix
AUTOFIX_TARGET          := $(AUTOFIX)/target

AUTOFIX_OUT             := $(OUT_DIR)/still-reject

AUTOFIX_PREPARE_TARGET  := $(AUTOFIX_TARGET)/.autofix_prepare_target
AUTOFIX_JOB             := $(AUTOFIX)/.autofix
AUTOFIX_PYTHON_JOB      := $(AUTOFIX)/.autofix_python

PATCHALL_JOB            := $(OUT_DIR)/reject/.patchall

METHOD_TO_BOSP_PYTHON_JOB := $(AUTOFIX)/.methodtobosp_python
SMALI_TO_BOSP_PYTHON_JOB := $(AUTOFIX)/.smalitobosp_python

################ merged_target_files ######################
OUT_BOOTABLE_IMAGES  := $(OUT_TARGET_DIR)/BOOTABLE_IMAGES
OUT_META             := $(OUT_TARGET_DIR)/META
OUT_OTA              := $(OUT_TARGET_DIR)/OTA
OUT_RECOVERY         := $(OUT_TARGET_DIR)/RECOVERY
OUT_SYSTEM           := $(OUT_TARGET_DIR)/SYSTEM
OUT_DATA             := $(OUT_TARGET_DIR)/DATA

OUT_RECOVERY_FSTAB   := $(OUT_RECOVERY)/RAMDISK/etc/recovery.fstab

OUT_SYSTEM_APP       := $(OUT_SYSTEM)/app
OUT_SYSTEM_FRAMEWORK := $(OUT_SYSTEM)/framework
OUT_SYSTEM_LIB       := $(OUT_SYSTEM)/lib
OUT_SYSTEM_BIN       := $(OUT_SYSTEM)/bin
OUT_BUILD_PROP       := $(OUT_SYSTEM)/build.prop

# convert filesystem_config to data
CONVERT_FILESYSTEM   := $(PORT_ROOT)/build/tools/convert_filesystem.py

OUT_MAC_PERMISSIONS_XML := $(OUT_SYSTEM)/etc/security/mac_permissions.xml

####################### board's release ###################
BOARD_RELEASE := $(PORT_ROOT)/flyme/release/arm

################# target-files zips #######################
PRJ_OUT_TARGET_ZIP := $(OUT_DIR)/target-files.zip
PRE_TARGET_ZIP := target-files.zip

################ overlay for project ######################
PRJ_OVERLAY           := overlay
PRJ_FRAMEWORK_OVERLAY := $(PRJ_OVERLAY)/framework-res/res
PRJ_OTA_OVERLAY       := $(PRJ_OVERLAY)/OTA
PRJ_PREBUILT_OVERLAY  := $(PRJ_OVERLAY)/prebuilt

PRJ_META_INF_OVERLAY       := $(PRJ_OVERLAY)/META-INF/com/google/android
PRJ_UPDATE_BINARY_OVERLAY  := $(PRJ_META_INF_OVERLAY)/update-binary
PRJ_UPDATER_SCRIPT_OVERLAY := $(PRJ_META_INF_OVERLAY)/updater-script
PRJ_UPDATER_SCRIPT_PART    := $(PRJ_META_INF_OVERLAY)/updater-script.part

################# board's overlay ###########################
#BOARD_OVERLAY           := $(PORT_ROOT)/board/frameworks/overlay
# TODO config different board, not hard code to be flyme
BOARD_OVERLAY           := $(PORT_ROOT)/flyme/overlay
BOARD_FRAMEWORK_OVERLAY := $(BOARD_OVERLAY)/frameworks/base/core/res/res

################## board's source ###########################
BOARD_SYSTEM        := $(BOARD_DIR)/system
BOARD_META          := $(BOARD_DIR)/META
BOARD_OTA           := $(BOARD_DIR)/OTA

BOARD_FRAMEWORK     := $(BOARD_SYSTEM)/framework
BOARD_FRAMEWORK_RES := $(BOARD_FRAMEWORK)/framework-res.apk

PREPARE_SOURCE      := $(BOARD_SYSTEM)/.preparesource

ifeq ($(wildcard $(BOARD_SYSTEM)),)
BOARD_SYSTEM_FOR_POS := $(BOARD_RELEASE)/system
else
BOARD_SYSTEM_FOR_POS := $(BOARD_SYSTEM)
endif

############## vendor framework-res smali dir #############
VENDOR_FRAMEWORK_RES_OUT := $(PRJ_ROOT)/framework-res

############## internal resource java position ############
FRWK_INTER_RES_POS := smali/com/android/internal

################# project prebuilt directory ##############
BOARD_SYSTEM_PREBUILT_DIR := $(PORT_ROOT)/board/rom/system
PRJ_SYSTEM_PREBUILT_DIR   := $(PRJ_OVERLAY)/system
PRJ_DATA_PREBUILT_DIR     := $(PRJ_OVERLAY)/data

###################### odex ###############################
PRODUCT_DIR            := odexupdate
SYSDIR                 := system
BOOTDIR                := $(SYSDIR)/framework

VENDOR_INIT_RC         := $(VENDOR_DIR)/BOOT/RAMDISK/init.rc

# do not change the order in DEFAULT_BOOT_CLASS_ODEX_ORDER
DEFAULT_BOOT_CLASS_ODEX_ORDER  := core.jar:core-junit.jar:bouncycastle.jar:ext.jar:framework.jar:android.policy.jar:services.jar:apache-xml.jar:filterfw.jar:mediatek-framework.jar:secondary_framework.jar

OUT_ODEX_DIR       := $(OUT_DIR)/$(PRODUCT_DIR)
OUT_ODEX_SYSTEM    := $(OUT_ODEX_DIR)/system
OUT_ODEX_FRAMEWORK := $(OUT_ODEX_SYSTEM)/framework
OUT_ODEX_APP       := $(OUT_ODEX_SYSTEM)/app
OUT_ODEX_META      := $(OUT_ODEX_DIR)/META

# the dalvik vm build version
# which will be used for preodex
DEFAULT_DALVIK_VM_BUILD := 27
DEXOPT_LIBS             := $(PORT_ROOT)/build/lib
################## target for server ######################
PRJ_TARGET_FILE_ODEX        := $(OUT_DIR)/target_files.zip.odex.zip

PRJ_SIGNED_TARGET_FILE      := $(OUT_DIR)/$(PRJ_NAME)-target-file-signed.zip
PRJ_SIGNED_IMAGES           := $(OUT_DIR)/signed-images.zip

PRJ_OUT_SERVER              := $(OUT_DIR)/server
PRJ_OUT_SERVER_IMAGES       := $(PRJ_OUT_SERVER)/image
PRJ_OUT_SERVER_OTA          := $(PRJ_OUT_SERVER)/ota
PRJ_SAVED_OTA_NAME          := $(OUT_DIR)/.ota_name
PRJ_SAVED_TARGET_NAME       := $(OUT_DIR)/.target_name

########################## init ###########################
FRAMEWORK_RES_SOURCE :=
PRJ_PUBLIC_XML       :=

BOARD_PREBUILT_APPS :=
BOARD_UPDATE_APPS   :=

TARGET_FILES_SYSTEM :=
TARGET_FILES_OTA    :=
TARGET_FILES_META   :=
OTA_TARGETS         :=

########################## MAKE ###########################
# if doesn't set MAKE, set it to make -j4
ifeq ($(strip $(MAKE)),)
MAKE := make -j4
endif

###################### build.prop #########################
VENDOR_BUILD_PROP       := $(VENDOR_SYSTEM)/build.prop

###################### tools in path ######################
AAPT           := aapt
ZIPALIGN       := zipalign

############### tools in $(PORT_BUILD)/tools ##############
PORT_BUILD_TOOLS         := $(PORT_BUILD)/tools
GET_PACKAGE              := $(PORT_BUILD_TOOLS)/getpackage.sh
GET_PUBLIC_XML           := $(PORT_BUILD_TOOLS)/getPublicXml.sh
INSTALL_FRAMEWORKS       := $(PORT_BUILD_TOOLS)/ifdir.sh

MAKE_BUILD_PROP          := $(PORT_BUILD_TOOLS)/make_build_prop.sh
PART_SMALI_APPEND        := $(PORT_BUILD_TOOLS)/partSmaliAppend.sh
UPDATE_INTERNAL_RESOURCE := $(PORT_BUILD_TOOLS)/UpInterrJava.py
UPDATE_FILE_SYSTEM       := $(PORT_BUILD_TOOLS)/UpdateFilesystem.py
FILE_UNION               := $(PORT_BUILD_TOOLS)/file_union.py

UPDATE_APKTOOL_YML_TOOLS := $(PORT_BUILD_TOOLS)/update_apktool_yml.sh
DIFFMAP_TOOL             := $(PORT_BUILD_TOOLS)/diffmap.sh
MODIFY_ID_TOOL           := $(PORT_BUILD_TOOLS)/modifyID.py
GENMAP_TOOL              := $(PORT_BUILD_TOOLS)/GenMap.py

RECOVERY_LINK            := $(PORT_BUILD_TOOLS)/releasetools/recoverylink.py
OTA_FROM_TARGET_FILES    := $(PORT_BUILD_TOOLS)/releasetools/ota_from_target_files
IMG_FROM_TARGET_FILES    := $(PORT_BUILD_TOOLS)/releasetools/img_from_target_files
SIGN_TARGET_FILES_APKS   := $(PORT_BUILD_TOOLS)/releasetools/sign_target_files_apks
NON_MTK_WRITE_RAW_IMAGE	 := $(PORT_BUILD_TOOLS)/releasetools/non_mtk_writeRawImage.py

DEX_OPT                  := $(PORT_BUILD_TOOLS)/dexopt
DEX_PRE_OPT              := $(PORT_BUILD_TOOLS)/dex-preopt
SIGN_JAR                 := $(PORT_BUILD_TOOLS)/signapk.jar
SIGN_APK_WITH_APKCERTS   := $(PORT_BUILD_TOOLS)/sign_apk_with_apkcerts.sh

PORT_CUSTOM_APP          := $(PORT_BUILD_TOOLS)/custom_app.sh
PORT_CUSTOM_JAR          := $(PORT_BUILD_TOOLS)/custom_jar.sh
PORT_CUSTOM_BOARD_ZIP    := $(PORT_BUILD_TOOLS)/custom_board_zip.sh
PORT_CUSTOM_TARGET_FILES := $(PORT_BUILD_TOOLS)/custom_targetfiles.sh
PORT_PREPARE_CUSTOM_JAR  := $(PORT_BUILD_TOOLS)/prepare_custom_jar.sh

FLASH_OTA_TO_DEVICE      := $(PORT_BUILD_TOOLS)/flash_ota_to_device.sh

TESTKEY_PEM := $(PORT_BUILD)/security/testkey.x509.pem
TESTKEY_PK  := $(PORT_BUILD)/security/testkey.pk8
# CERTS_PATH only for generate the apkcerts.txt
CERTS_PATH  := build/security
OTA_CERT := $(PORT_ROOT)/$(CERTS_PATH)/testkey


############### tools in $(PORT_ROOT)/tools ###############
PORT_TOOLS      := $(PORT_ROOT)/tools
APKTOOL         := $(PORT_TOOLS)/apktool
OTA_NORMALIZE	:= $(PORT_TOOLS)/otanormalize

NAME_TO_ID_TOOL := $(PORT_TOOLS)/nametoid
ID_TO_NAME_TOOL := $(PORT_TOOLS)/idtoname

SCHECK          := $(PORT_TOOLS)/smaliparser/SCheck
AUTOFIX_TOOL    := python $(PORT_TOOLS)/smaliparser/reject.py

PUSH                 := $(PORT_TOOLS)/push
FLASH                := $(PORT_TOOLS)/bootimgpack/flash.py
DEEFAULT_PERMISSION  ?= 644

################### tools for project ####################
PRJ_CUSTOM_TARGETFILES := $(PRJ_ROOT)/custom_targetfiles.sh
PRJ_CUSTOM_APP         := $(PRJ_ROOT)/custom_app.sh
PRJ_CUSTOM_JAR         := $(PRJ_ROOT)/custom_jar.sh
PRJ_CUSTOM_BUILDPROP   := $(PRJ_ROOT)/custom_buildprop.sh
PRJ_CUSTOM_SCRIPT      := $(PRJ_ROOT)/custom_updater_script.sh
