# board_default.mk

PREBUILT_MK        := $(PORT_BUILD)/configs/prebuilt.mk
CONFIG_PREBUILT    := $(PORT_TOOLS)/config/config_prebuilt.py
BASE_VENDOR_SYSTEM := $(PORT_ROOT)/devices/base/vendor/system

ifeq ($(wildcard $(PREBUILT_MK)),)
ifneq ($(wildcard $(BASE_VENDOR_SYSTEM)),)
ifneq ($(wildcard $(BOARD_RELEASE)/system),)
BOARD_SYSTEM_FOR_GENERATE_PREBUILT := $(BOARD_RELEASE)/system
else
ifneq ($(wildcard $(BOARD_SYSTEM)),)
BOARD_SYSTEM_FOR_GENERATE_PREBUILT := $(BOARD_SYSTEM)
endif # ifneq ($(wildcard $(BOARD_SYSTEM)),)
endif # ifneq ($(wildcard $(BOARD_RELEASE)/system),)

ifneq ($(BOARD_SYSTEM_FOR_GENERATE_PREBUILT),)
PREBUILT_MK          := $(OUT_OBJ_DIR)/prebuilt.mk
generate_prebuilt_mk := $(shell mkdir -p $(OUT_OBJ_DIR) && $(CONFIG_PREBUILT) $(PREBUILT_MK) $(BOARD_SYSTEM_FOR_GENERATE_PREBUILT) $(BASE_VENDOR_SYSTEM))
endif 
endif # ifneq ($(wildcard $(BASE_VENDOR_SYSTEM)),)
endif # ifeq ($(wildcard $(PREBUILT_MK)),)

ifneq ($(wildcard $(PREBUILT_MK)),)
include $(PREBUILT_MK)
endif #ifneq ($(wildcard $(PREBUILT_MK)),)

PREBUILT_64_MK := $(PORT_BUILD)/configs/prebuilt_64.mk
ifneq ($(wildcard $(PREBUILT_64_MK)),)
ifneq ($(wildcard $(VENDOR_SYSTEM)/lib64),)
include $(PREBUILT_64_MK)
endif
endif

include $(PORT_BUILD)/configs/black_prebuilt.mk
BOARD_PREBUILT := $(filter-out $(BLACK_LIST_DIRS) $(BLACK_LIST),$(BOARD_PREBUILT))
BOARD_PREBUILT_DIRS := $(patsubst %/,%,$(filter-out $(BLACK_LIST_DIRS),$(patsubst %,%/,$(BOARD_PREBUILT_DIRS))))

include $(PORT_BUILD)/configs/board_override.mk

ifeq ($(strip $(BOARD_PRESIGNED_APPS)),)
$(info Warning: use default presigned apps, $(BOARD_PRESIGNED_APPS_DEFAULT))
BOARD_PRESIGNED_APPS := $(BOARD_PRESIGNED_APPS_DEFAULT)
endif

# get all of the files in $(BOARD_PREBUILT_DIRS)
$(foreach dirname,$(BOARD_PREBUILT_DIRS), \
    $(eval BOARD_PREBUILT += \
    $(sort $(filter-out $(BLACK_LIST_DIRS) $(BLACK_LIST),$(patsubst $(BOARD_SYSTEM_FOR_POS)/%,%,$(call get_all_files_in_dir,$(BOARD_SYSTEM_FOR_POS)/$(dirname)))))))

BOARD_PREBUILT_DIRS := $(sort $(strip $(board_saved_dirs)) $(BOARD_PREBUILT_DIRS))
BOARD_PREBUILT := $(sort $(strip $(board_saved_files)) $(BOARD_PREBUILT))

ifeq ($(strip $(LOW_RAM_DEVICE)),true)
$(info low ram device, remove $(BOARD_PREBUILT_LOW_RAM_REMOVE))
BOARD_PREBUILT := $(filter-out $(BOARD_PREBUILT_LOW_RAM_REMOVE),$(BOARD_PREBUILT))
endif

REDUCE_RESOURCES_EXCLUDE_APPS := $(strip $(REDUCE_RESOURCES_EXCLUDE_APPS))
BOARD_MODIFY_RESID_FILES      := $(strip $(BOARD_MODIFY_RESID_FILES))
BOARD_PRESIGNED_APPS          := $(strip $(BOARD_PRESIGNED_APPS))
BOARD_PREBUILT_LOW_RAM_REMOVE := $(strip $(BOARD_PREBUILT_LOW_RAM_REMOVE))
BOARD_PREBUILT                := $(strip $(BOARD_PREBUILT))

