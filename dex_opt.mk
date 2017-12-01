# dex_opt.mk

ifneq ($(wildcard $(VENDOR_INIT_RC)),)
BOOT_CLASS_ODEX_ORDER := $(shell grep "^[ \t]*export[ \t]*BOOTCLASSPATH" $(VENDOR_INIT_RC) \
				| head -n1 \
				| awk '{print $$NF}' \
				| sed 's/\/system\/framework\///g')
endif

ifeq ($(strip $(BOOT_CLASS_ODEX_ORDER)),)
BOOT_CLASS_ODEX_ORDER := $(DEFAULT_BOOT_CLASS_ODEX_ORDER)
endif

ifeq ($(strip $(DALVIK_VM_BUILD)),)
DALVIK_VM_BUILD := $(DEFAULT_DALVIK_VM_BUILD)
endif

#$(info # BOOT_CLASS_ODEX_ORDER:$(BOOT_CLASS_ODEX_ORDER))

LD_LIBRARY_PATH := $(DEXOPT_LIBS):$(LD_LIBRARY_PATH)
LD_LIBRARY_PATH := $(DEXOPT_LIBS)/dvm_$(DALVIK_VM_BUILD):$(LD_LIBRARY_PATH)

#$(info # LD_LIBRARY_PATH: $(LD_LIBRARY_PATH))

$(PRJ_TARGET_FILE_ODEX): prepare-odexupdate dex-framework dex-apps
	$(hide) mv $(OUT_ODEX_SYSTEM) $(OUT_ODEX_DIR)/SYSTEM
	$(hide) echo ">>> begin update filessystem_config.txt"
	$(hide) $(UPDATE_FILE_SYSTEM) $(OUT_ODEX_META)/filesystem_config.txt $(OUT_ODEX_DIR)/SYSTEM
	$(hide) echo ">>> begin zip all"
	$(hide) cd $(OUT_ODEX_DIR) && zip -q -r -y target_files.odex.zip * && cd -
	$(hide) mv $(OUT_ODEX_DIR)/target_files.odex.zip $(PRJ_TARGET_FILE_ODEX)
	$(hide) rm -rf $(OUT_ODEX_DIR)
	$(hide) echo ">>> $(PRJ_TARGET_FILE_ODEX) is done!"

.PHONY: prepare-odexupdate
prepare-odexupdate: $(PRJ_OUT_TARGET_ZIP)
	$(hide) echo ">>> unzip $(PRJ_OUT_TARGET_ZIP) to $(OUT_ODEX_DIR)"
	$(hide) rm -rf $(OUT_ODEX_DIR)
	$(hide) mkdir -p $(OUT_ODEX_DIR)
	$(hide) unzip -q $(PRJ_OUT_TARGET_ZIP) -d $(OUT_ODEX_DIR)
	$(hide) if [ -d $(OUT_ODEX_DIR)/SYSTEM ];then \
			mv $(OUT_ODEX_DIR)/SYSTEM  $(OUT_ODEX_DIR)/system; \
		fi

.PHONY: dex-framework
dex-framework: BOOT_CLASSES := $(subst :, ,$(BOOT_CLASS_ODEX_ORDER))
dex-framework: prepare-odexupdate
	$(hide) echo ">>> dex frameworks"
	$(hide) $(foreach jar,$(BOOT_CLASSES),\
			$(call dex_opt_jar,$(patsubst %.jar,%,$(jar))))
	$(hide) need_odex_jars=$$(ls $(OUT_ODEX_FRAMEWORK)/*.jar); \
		for jar in $$need_odex_jars; do \
			jar=$$(basename $$jar); \
			jar=$${jar%.*}; \
			$(call dex_opt_jar,$$jar) \
		done
	$(hide) echo ">>> dex frameworks done"

.PHONY: dex-apps
dex-apps: dex-framework
	$(hide) echo ">>> begin dex apps"
	$(hide) need_odex_apks=$$(ls $(OUT_ODEX_APP)/*.apk); \
		for apk in $$need_odex_apks; do \
			apk=$$(basename $$apk); \
			apk=$${apk%.*}; \
			$(call dex_opt_app,$$apk) \
		done
	$(hide) echo ">>> dex apps done"
	
