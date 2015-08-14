# board_override.mk

# add prebuilt dirs which should be override by board
BOARD_PREBUILT_DIRS += \
	media/audio \
	app \
	priv-app \
	etc/channel_files

# add prebuilt files which should be override by board
BOARD_PREBUILT_DEFAULT := \
	bin/flymed \
	bin/flymePerf \
	bin/pppoe \
	bin/gdbserver \
	bin/hostapd_cli \
	bin/keystore_cli \
	bin/nmbd \
	bin/pngtest \
	bin/r \
	bin/radiooptions \
	bin/showlease \
	bin/smbd \
	bin/smbpasswd \
	bin/tracepath \
	bin/tracepath6 \
	bin/traceroute6 \
	bin/wpa_cli \
	xbin/add-property-tag \
	xbin/check-lost+found \
	xbin/cpustats \
	xbin/dhdutil \
	xbin/fio \
	xbin/ksminfo \
	xbin/latencytop \
	xbin/librank \
	xbin/ltrace \
	xbin/memtrack \
	xbin/memtrack_share \
	xbin/micro_bench \
	xbin/micro_bench_static \
	xbin/procmem \
	xbin/procrank \
	xbin/puncture_fs \
	xbin/rawbu \
	xbin/sane_schedstat \
	xbin/showmap \
	xbin/showslab \
	xbin/sqlite3 \
	xbin/strace \
	xbin/su \
	xbin/taskstats \
        framework/flyme-res/flyme-res.apk \
        framework/com.meizu.camera.jar \
        framework/meizu2_jcifs.jar \
        framework/telephony-meizu.jar

$(call resetPosition,BOARD_PREBUILT_DEFAULT,$(BOARD_SYSTEM_FOR_POS))
BOARD_PREBUILT += $(BOARD_PREBUILT_DEFAULT)

# define the apk and jars which need modify the res id
BOARD_MODIFY_RESID_FILES := \
        priv-app/Telecom/Telecom.apk \
        priv-app/TeleService/TeleService.apk \
        priv-app/Dialer/Dialer.apk \
        priv-app/ContactsProvider/ContactsProvider.apk \
        priv-app/DownloadProvider/DownloadProvider.apk \
        priv-app/Settings/Settings.apk \
        priv-app/Browser/Browser.apk \
        priv-app/Contacts/Contacts.apk \
        priv-app/SystemUI/SystemUI.apk \
        priv-app/SettingsProvider/SettingsProvider.apk \
        priv-app/Keyguard/Keyguard.apk \
        priv-app/TelephonyProvider/TelephonyProvider.apk \
        priv-app/MediaProvider/MediaProvider.apk \
        app/MzSimContacts/MzSimContacts.apk \
        app/MzBlockService/MzBlockService.apk \
        app/PackageInstaller/PackageInstaller.apk \
        app/Mms/Mms.apk \
	framework/flyme-telephony-common.jar \
	framework/flyme-framework.jar

$(call resetPosition,BOARD_MODIFY_RESID_FILES,$(BOARD_SYSTEM_FOR_POS))

BOARD_PREBUILT_LOW_RAM_REMOVE := \

$(call resetPosition,BOARD_PREBUILT_LOW_RAM_REMOVE,$(BOARD_PREBUILT_LOW_RAM_REMOVE))

########### property ######################
BUILD_DATE := $(shell date '+%Y%m%d%H%M%S')
ifeq ($(strip $(VERSION_NUMBER)),)
VERSION_NUMBER := builder.$(BUILD_DATE)_R
endif #ifeq ($(strip $(VERSION_NUMBER)),)

PRODUCT_BRAND := $(shell $(call getprop,ro.product.brand,$(VENDOR_SYSTEM)/build.prop))
TARGET_PRODUCT := $(shell $(call getprop,ro.product.name,$(VENDOR_SYSTEM)/build.prop))
TARGET_DEVICE := $(shell $(call getprop,ro.product.device,$(VENDOR_SYSTEM)/build.prop))
DISPLAY_VERSION := $(shell $(call getprop_filter_version,ro.build.display.id,$(BOARD_SYSTEM)/build.prop))

PLATFORM_VERSION := $(shell $(call getprop,ro.build.version.release,$(VENDOR_SYSTEM)/build.prop))
BUILD_ID := $(shell $(call getprop,ro.build.id,$(VENDOR_SYSTEM)/build.prop))
BUILD_NUMBER := $(VERSION_NUMBER)
BF_BUILD_NUMBER := $(BUILD_NUMBER)
TARGET_BUILD_VARIANT := $(shell $(call getprop,ro.build.type,$(VENDOR_SYSTEM)/build.prop))
BUILD_VERSION_TAGS := $(shell $(call getprop,ro.build.tags,$(VENDOR_SYSTEM)/build.prop))

BOARD_PROPERTY_OVERRIDES := \
    ro.build.version.incremental=$(BUILD_NUMBER) \
    ro.build.fingerprint=$(PRODUCT_BRAND)/$(TARGET_PRODUCT)/$(TARGET_DEVICE):$(PLATFORM_VERSION)/$(BUILD_ID)/$(BF_BUILD_NUMBER):$(TARGET_BUILD_VARIANT)/$(BUILD_VERSION_TAGS) \
    ro.build.description=$(TARGET_PRODUCT)-$(TARGET_BUILD_VARIANT) $(PLATFORM_VERSION) $(BUILD_ID) $(BUILD_NUMBER) $(BUILD_VERSION_TAGS) \
    ro.build.date=$(shell date) \
    ro.build.date.utc=$(shell date +%s) \
    ro.build.user=$(USER) \
    ro.build.host=$(shell hostname)

BOARD_PROPERTY_OVERRIDES += \
    ro.build.inside.id=$(PLATFORM_VERSION)-$(BUILD_DATE) \
    ro.build.mask.id=$(PLATFORM_VERSION)-$(shell date +%s)_R

BOARD_PROPERTY_FOLLOW_BASE := \
    persist.sys.ui.hw \
    persist.sys.disable_blur_view \
    persist.sys.static_blur_mode \
    persist.sys.timezone \
    persist.sys.meizu.region \
    persist.sys.meizu.codepage \
    ro.product.locale.language \
    ro.product.locale.region \
    ro.config.notification_sound \
    ro.config.ringtone \
    ro.config.alarm_alert \
    ro.config.mms_sound \
    ro.config.email_sound \
    ro.config.calendar_sound \
    ro.meizu.region.enable \
    ro.meizu.contactmsg.auth \
    ro.meizu.customize.pccw \
    ro.meizu.autorecorder \
    ro.meizu.visualvoicemail \
    ro.meizu.permanentkey \
    ro.meizu.setupwizard.flyme \
    ro.meizu.setupwizard.setlang \
    ro.meizu.security \
    sys.meizu.m35x.white.config \
    sys.meizu.white.config \
    ro.meizu.rom.config \
    ro.meizu.voip.support \
    ro.meizu.sip.support \
    ro.flyme.hideinfo \
    persist.sys.use.flyme.icon \
    ro.build.display.id

BOARD_SERVICES += \

BOARD_PREBUILT_PACKAGE_framework := \
	flyme \
	meizu \
	com/flyme \
	com/meizu

# if the app was set in REDUCE_RESOURCES_EXCLUDE_APPS, it will not reduce resources
REDUCE_RESOURCES_EXCLUDE_APPS += BaiduCamera

$(call resetPositionApp,REDUCE_RESOURCES_EXCLUDE_APPS,$(BOARD_SYSTEM_FOR_POS))

ifeq ($(filter Phone,$(vendor_modify_apps)),)
ifneq ($(strip $(call isExist,Phone.apk,$(VENDOR_SYSTEM))),)
ifneq ($(strip $(call isExist,Phone.apk,$(BOARD_SYSTEM_FOR_POS))),)
NEED_COMPELETE_MODULE_PAIR += \
	app/Phone.apk:Phone
endif # ifneq ($(call posOfApp,Phone,$(BOARD_SYSTEM_FOR_POS)),)
endif # ifneq ($(call posOfApp,Phone,$(VENDOR_SYSTEM)),)
endif # ifeq ($(filter Phone,$(vendor_modify_apps)),)

ifeq ($(filter android.policy,$(vendor_modify_jars)),)
NEED_COMPELETE_MODULE_PAIR += \
	framework/android.policy.jar:android.policy.jar.out
endif

VENDOR_COM_MODULE_PAIR := \
	framework/core.jar:core.jar.out

# BOARD_PRESIGNED_APPS set here is to proguard, if can not find apkcerts.txt, this would worked!
BOARD_PRESIGNED_APPS_DEFAULT := \

$(call resetPosition,BOARD_PRESIGNED_APPS_DEFAULT,$(BOARD_SYSTEM_FOR_POS))

ifeq ($(OTA_ZIP),)
ifeq ($(ROMER),)
PRJ_FULL_OTA_ZIP := $(OUT_DIR)/flyme_$(TARGET_DEVICE)_$(DISPLAY_VERSION).zip
else
PRJ_FULL_OTA_ZIP := $(OUT_DIR)/flyme_$(TARGET_DEVICE)_$(ROMER)_$(DISPLAY_VERSION).zip
endif
else
PRJ_FULL_OTA_ZIP := $(OTA_ZIP)
endif

ifeq ($(TARGET_ZIP),)
PRJ_TARGET_ZIP := $(OUT_DIR)/target_files_$(TARGET_DEVICE)_$(BUILD_DATE).zip
else
PRJ_TARGET_ZIP := $(TARGET_ZIP)
endif
