# board_override.mk

# add prebuilt files which should be override by board
BOARD_PREBUILT_DEFAULT := \

$(call resetPosition,BOARD_PREBUILT_DEFAULT,$(BOARD_SYSTEM_FOR_POS))
BOARD_PREBUILT += $(BOARD_PREBUILT_DEFAULT)

# define the apk and jars which need modify the res id
BOARD_MODIFY_RESID_FILES := \
    app/ConnectivitySettings/ConnectivitySettings.apk \
    app/MzBlockService/MzBlockService.apk \
    app/MzSimContacts/MzSimContacts.apk \
    framework/flyme-framework.jar \
    framework/flyme-telephony-common.jar \
    priv-app/Contacts/Contacts.apk \
    priv-app/ContactsProvider/ContactsProvider.apk \
    priv-app/Dialer/Dialer.apk \
    priv-app/DownloadProvider/DownloadProvider.apk \
    priv-app/InCallUI/InCallUI.apk \
    priv-app/Keyguard/Keyguard.apk \
    priv-app/ManagedProvisioning/ManagedProvisioning.apk \
    priv-app/MediaProvider/MediaProvider.apk \
    priv-app/Mms/Mms.apk \
    priv-app/PackageInstaller/PackageInstaller.apk \
    priv-app/SettingsProvider/SettingsProvider.apk \
    priv-app/Settings/Settings.apk \
    priv-app/SystemUI/SystemUI.apk \
    priv-app/Telecom/Telecom.apk \
    priv-app/TelephonyProvider/TelephonyProvider.apk \
    priv-app/TeleService/TeleService.apk


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
TARGET_MODEL := $(shell $(call getprop_escape_space,ro.product.model,$(VENDOR_SYSTEM)/build.prop))
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
    persist.sys.disable_blur_view \
    persist.sys.disable_glass_blur \
    persist.sys.keyguard_intercep \
    persist.sys.meizu.codepage \
    persist.sys.meizu.region \
    persist.sys.static_blur_mode \
    persist.sys.use.flyme.icon \
    ro.build.display.id \
    ro.config.alarm_alert \
    ro.config.calendar_sound \
    ro.config.email_sound \
    ro.config.mms_sound \
    ro.config.notification_sound \
    ro.config.ringtone \
    ro.flyme.hideinfo \
    ro.flyme.published \
    ro.flyme.version \
    ro.meizu.autorecorder \
    ro.meizu.contactmsg.auth \
    ro.meizu.customize.pccw \
    ro.meizu.permanentkey \
    ro.meizu.published.type \
    ro.meizu.region.enable \
    ro.meizu.rom.config \
    ro.meizu.security \
    ro.meizu.setupwizard.flyme \
    ro.meizu.setupwizard.setlang \
    ro.meizu.sip.support \
    ro.meizu.upgrade.config \
    ro.meizu.visualvoicemail \
    ro.meizu.voip.support \
    sys.meizu.m35x.white.config \
    sys.meizu.white.config


BOARD_SERVICES += \

BOARD_PREBUILT_FOLDER := \
    flyme \
    meizu \
    com/flyme \
    com/meizu

BOARD_PREBUILT_PACKAGE_framework := $(BOARD_PREBUILT_FOLDER)

BOARD_PREBUILT_PACKAGE_services := $(BOARD_PREBUILT_FOLDER)

# if the app was set in REDUCE_RESOURCES_EXCLUDE_APPS, it will not reduce resources
REDUCE_RESOURCES_EXCLUDE_APPS += \

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
PRJ_FULL_OTA_ZIP := $(OUT_DIR)/flyme_$(TARGET_MODEL)_$(DISPLAY_VERSION).zip
else
PRJ_FULL_OTA_ZIP := $(OUT_DIR)/flyme_$(TARGET_MODEL)_$(ROMER)_$(DISPLAY_VERSION).zip
endif
else
PRJ_FULL_OTA_ZIP := $(OTA_ZIP)
endif

ifeq ($(TARGET_ZIP),)
PRJ_TARGET_ZIP := $(OUT_DIR)/target_files_$(TARGET_MODEL)_$(DISPLAY_VERSION)_$(BUILD_DATE).zip
else
PRJ_TARGET_ZIP := $(TARGET_ZIP)
endif

ifeq ($(strip $(PRODUCE_INTERNATIONAL_ROM)),true)
BOARD_PROPERTY_FOLLOW_BASE += \

else
BOARD_PROPERTY_FOLLOW_BASE += \
    persist.sys.ui.hw \
    persist.sys.timezone \
    ro.product.locale

endif
