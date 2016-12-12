# prebuilt.mk

# config for vendor, which need remove from vendor files
PREBUILT_TARGET      :=
BOARD_PREBUILT_FILES :=



################# prepare-vendor ##############################
# remove the files which in vendor_remove_dirs
VENDOR_PREBUILT_FILES := $(ALL_VENDOR_FILES)

$(foreach removeDirs,$(VENDOR_REMOVE_DIRS), \
    $(eval VENDOR_PREBUILT_FILES:=$(filter-out $(removeDirs)/%,$(VENDOR_PREBUILT_FILES))))

# remove the files which define in vendor_remove_files
VENDOR_PREBUILT_FILES:=$(filter-out $(VENDOR_REMOVE_FILES),$(VENDOR_PREBUILT_FILES))

#$(info # PRJ_CUSTOM_TARGET:$(PRJ_CUSTOM_TARGET))
# remove the files which are define in project
VENDOR_PREBUILT_FILES:=$(filter-out $(PRJ_CUSTOM_TARGET), $(VENDOR_PREBUILT_FILES))

VENDOR_PREBUILT_FILES += $(VENDOR_PREBUILT_APPS)

VENDOR_SAVED_APP_FILES := $(vendor_saved_apps)
$(call getAllFilesInApp,VENDOR_SAVED_APP_FILES,$(VENDOR_SYSTEM))

VENDOR_SAVED_APP_FILES := $(filter-out %.apk,$(VENDOR_SAVED_APP_FILES))
VENDOR_SAVED_APP_FILES := $(filter-out %.odex,$(VENDOR_SAVED_APP_FILES))

VENDOR_SAVED_APP_FILES := $(patsubst $(VENDOR_SYSTEM)/%,%,$(VENDOR_SAVED_APP_FILES))
VENDOR_PREBUILT_FILES += $(VENDOR_SAVED_APP_FILES)

############## prepare board prebuilt #########################
# filter the target which are not prebuilt

BOARD_REMOVE_APP_FILES := $(board_remove_apps) $(vendor_saved_apps)
$(call getAllFilesInApp,BOARD_REMOVE_APP_FILES,$(BOARD_SYSTEM_FOR_POS))

BOARD_REMOVE_APP_FILES := $(patsubst $(BOARD_SYSTEM_FOR_POS)/%,%,$(BOARD_REMOVE_APP_FILES))
BOARD_PREBUILT := $(filter-out $(BOARD_REMOVE_APP_FILES),$(BOARD_PREBUILT))

BOARD_PREBUILT_FILES += $(strip $(BOARD_PREBUILT_APPS) $(BOARD_PREBUILT))
BOARD_PREBUILT_FILES := $(sort $(strip $(filter-out $(PRJ_CUSTOM_TARGET) $(BOARD_MODIFY_RESID_FILES),$(BOARD_PREBUILT_FILES))))

BOARD_SIGNED_APPS    := $(filter %.apk,$(BOARD_PREBUILT_FILES))
BOARD_PREBUILT_FILES := $(filter-out %.apk,$(BOARD_PREBUILT_FILES))

# filter these files which are not exist!!
BOARD_PREBUILT_FILES := $(filter $(ALL_BOARD_FILES),$(BOARD_PREBUILT_FILES))
BOARD_PREBUILT_FILES := $(filter-out $(VENDOR_PREBUILT_APPS),$(BOARD_PREBUILT_FILES))

VENDOR_PREBUILT_FILES := $(filter-out $(BOARD_PREBUILT_FILES),$(VENDOR_PREBUILT_FILES))

# filter the apks, which need sign
VENDOR_SIGN_APPS := $(filter %.apk,$(VENDOR_PREBUILT_FILES))
$(foreach apk,$(VENDOR_SIGN_APPS),\
    $(eval SIGN_APPS += $(VENDOR_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))

#$(info # VENDOR_SIGN_APPS:$(VENDOR_SIGN_APPS))

VENDOR_PREBUILT_FILES := $(filter-out %.apk,$(VENDOR_PREBUILT_FILES))

################## define the prebuilt targets ###############

$(foreach file,$(VENDOR_PREBUILT_FILES),\
     $(eval $(call prebuilt_template,$(VENDOR_SYSTEM)/$(file),$(OUT_SYSTEM)/$(file))))

$(foreach file,$(BOARD_PREBUILT_FILES),\
     $(eval $(call prebuilt_template,$(BOARD_SYSTEM)/$(file),$(OUT_SYSTEM)/$(file))))

############ bootanimation&shutdownanimation   ###############
RESOLUTION := $(strip $(RESOLUTION))
ifneq ($(RESOLUTION),)
	ifneq ($(wildcard $(BOARD_BOOTANIMATION)/bootanimation_$(RESOLUTION).zip),)
        $(eval $(call prebuilt_template,$(BOARD_BOOTANIMATION)/bootanimation_$(RESOLUTION).zip,$(OUT_SYSTEM)/media/bootanimation.zip))
	endif
	ifneq ($(wildcard $(BOARD_BOOTANIMATION)/shutanimation_$(RESOLUTION).zip),)
        $(eval $(call prebuilt_template,$(BOARD_BOOTANIMATION)/shutanimation_$(RESOLUTION).zip,$(OUT_SYSTEM)/media/shutanimation.zip))
	endif
endif

###################### prebuilt ##############################
OTA_TARGETS += prebuilt
prebuilt: $(PREBUILT_TARGET)
	$(hide) echo "<< generate |target-files|PREBUILT| done"

