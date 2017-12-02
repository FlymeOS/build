OEM_TARGET_DIR		:= $(OUT_DIR)/oem_target_files
OEM_TARGET_ZIP		:= $(OUT_DIR)/oem_target_files.zip
OEM_TARGET_STD_ZIP	:= $(OUT_DIR)/oem_target_files.zip.std.zip
VENDOR_TARGET_ZIP	:= $(OUT_DIR)/vendor_target_files.zip
VENDOR_TARGET_DIR	:= $(OUT_DIR)/vendor_target_files
VENDOR_OTA_ZIP		:= $(OUT_DIR)/vendor_ota.zip
METAINF			:= $(VENDOR_DIR)/METAINF
TARGET_FILES_FROM_DEVICE:= $(PORT_BUILD_TOOLS)/target_files_from_device.sh

##################### newproject ########################
./PHONY: newproject
ifeq ($(PRODUCE_IS_AB_UPDATE),true)
newproject: prepare-vendor prepare-root unpack-boot prepare-vendor-recovery decodefile update_file_system_config
else
newproject: prepare-vendor unpack-boot prepare-vendor-recovery decodefile update_file_system_config
endif
	$(hide) if [ -f $(OUT_DIR)/build-info-to-user.txt ];then \
			cat $(OUT_DIR)/build-info-to-user.txt; \
		fi
	$(hide) echo "< newproject done"
	$(hide) echo "========================================================================================"
	$(hide) echo "Recommended Command:"
	$(hide) echo "    make vendorota  ->  build a vendor ota package to test whether newproject correctly."
	$(hide) echo "========================================================================================"

$(OEM_TARGET_ZIP): $(PRJ_RECOVERY_FSTAB)
	$(hide) echo ">> prepare vendor ..."
	$(hide) echo ">>> generate vendor target files ..."
	$(hide) $(TARGET_FILES_FROM_DEVICE) target $(PRODUCE_IS_AB_UPDATE)
	$(hide) echo "<<< generate vendor target files done"

$(OEM_TARGET_STD_ZIP): $(OEM_TARGET_ZIP)
	$(hide) echo ">>> normalize the $(OEM_TARGET_ZIP) ..."
	$(hide) $(OTA_NORMALIZE) --input $(OEM_TARGET_ZIP)
	$(hide) echo "<<< normalize the $(OEM_TARGET_ZIP) done"

./PHONY: prepare-vendor
prepare-vendor: $(OEM_TARGET_STD_ZIP)
	$(hide) rm -rf $(VENDOR_DIR)
	$(hide) echo ">>> unzip $(OEM_TARGET_STD_ZIP) to $(VENDOR_DIR) ..."
	$(hide) unzip -q $(OEM_TARGET_STD_ZIP) -d $(VENDOR_DIR)
	$(hide) echo "<<< unzip $(OEM_TARGET_STD_ZIP) to $(VENDOR_DIR) done"
	$(hide) if [ -d $(VENDOR_DIR)/SYSTEM ]; then mv $(VENDOR_DIR)/SYSTEM $(VENDOR_DIR)/system; fi
	$(hide) echo "<< prepare vendor done"
	$(hide) echo "* out ==> $(VENDOR_DIR)"
	$(hide) echo " "

ifeq ($(PRJ_RECOVERY_FSTAB),$(wildcard $(PRJ_RECOVERY_FSTAB)))
#$(info # use $(PRJ_RECOVERY_FSTAB))
#nop
:
else
$(PRJ_RECOVERY_FSTAB): unpack-recovery
	$(hide) cp $(OUT_OBJ_RECOVERY_FSTAB) $@
	$(hide) rm -rf $(OUT_OBJ_RECOVERY)
	$(hide) echo "* get recovery.fstab ==> $(PRJ_RECOVERY_FSTAB)"
	$(hide) echo " "
endif

./PHONY: prepare-root
prepare-root :
	$(hide) echo ">> prepare root ..."
	$(hide) rm -rf $(PRJ_ROOT)/ROOT
	$(hide) if [ -d $(VENDOR_DIR)/ROOT ]; then cp -a $(VENDOR_DIR)/ROOT $(PRJ_ROOT); fi;
	$(hide) if [ -f $(PRJ_ROOT)/ROOT/file_contexts.bin ]; then \
			echo ">> unpack $(PRJ_ROOT)/ROOT/file_contexts.bin ...";  \
			$(SEFCONTEXT_TOOL) -o $(PRJ_ROOT)/ROOT/file_contexts $(PRJ_ROOT)/ROOT/file_contexts.bin; \
			echo "<< unpack $(PRJ_ROOT)/ROOT/file_contexts.bin done";  \
		fi
	$(hide) echo "<< prepare root done"

./PHONY: prepare-vendor-boot
prepare-vendor-boot : unpack-boot prepare-vendor
	$(hide) echo ">> prepare vendor boot ..."
	$(hide) rm -rf $(VENDOR_BOOT)
	$(hide) if [ -d $(OUT_OBJ_BOOT) ]; then mv $(OUT_OBJ_BOOT) $(VENDOR_BOOT); fi;
	$(hide) echo "<< prepare vendor boot done"

./PHONY: prepare-vendor-recovery
prepare-vendor-recovery: prepare-vendor
	$(hide) echo ">> prepare vendor recovery ..."
	$(hide) if [ -f $(VENDOR_SYSTEM)/build.prop ];then \
			echo ">>> auto catch the recovery prop ..."; \
			mkdir -p $(VENDOR_RECOVERY_RAMDISK); \
			TMPPROP=$$(grep "^ro.product.device=" $(VENDOR_SYSTEM)/build.prop); \
			if [ "$$TMPPROP" != "" ];then echo $$TMPPROP >  $(VENDOR_RECOVERY_RAMDISK)/default.prop; fi; \
			TMPPROP=$$(grep "^ro.build.product=" $(VENDOR_SYSTEM)/build.prop); \
			if [ "$$TMPPROP" != "" ];then echo $$TMPPROP >> $(VENDOR_RECOVERY_RAMDISK)/default.prop; fi; \
			echo "<<< auto catch the recovery prop done"; \
		fi
	$(hide) echo "<< prepare vendor recovery done"


################ decode files ###########################

define decode_files
$(2): ifoemvendor
	$(hide) echo ">>> decode $(1) $(2) ..."
	$(hide) rm -rf $(2)
	$(hide) $(APKTOOL) d -t $(APKTOOL_VENDOR_TAG) $(1) -o $(2)
	$(hide) echo "<<< decode $(1) $(2) done"
endef

PRJ_DECODE_APKS		:= $(strip framework-res)
PRJ_DECODE_JARS		:= $(strip $(vendor_modify_jars))
PRJ_DECODE_APKS_OUT	:= $(sort $(strip $(patsubst %,$(PRJ_ROOT)/%,$(PRJ_DECODE_APKS))))
PRJ_DECODE_JARS_OUT	:= $(sort $(strip $(patsubst %,$(PRJ_ROOT)/%.jar.out,$(PRJ_DECODE_JARS))))

$(foreach file,$(PRJ_DECODE_APKS),\
	$(eval $(call decode_files, \
		$(patsubst %,$(VENDOR_SYSTEM)/framework/%.apk,$(file)), \
		$(patsubst %,$(PRJ_ROOT)/%,$(file)))))

$(foreach file,$(PRJ_DECODE_JARS),\
	$(eval $(call decode_files, \
		$(patsubst %,$(VENDOR_SYSTEM)/framework/%.jar,$(file)), \
		$(patsubst %,$(PRJ_ROOT)/%.jar.out,$(file)))))

ifoemvendor: prepare-vendor
	$(hide) $(call apktool_if_vendor,$(VENDOR_FRAMEWORK))

./PHONY: decodefile
decodefile: $(PRJ_DECODE_APKS_OUT) $(PRJ_DECODE_JARS_OUT)
	$(hide) echo "<< decode apk and jar done"

###################### vendor ota ########################
./PHONY: vendorota oemotarom

vendorota oemotarom: $(VENDOR_OTA_ZIP)
	$(hide) echo "* out ==> $(VENDOR_OTA_ZIP)"

$(VENDOR_TARGET_ZIP): $(VENDOR_RECOVERY_FSTAB) bootimage
	$(hide) echo ">> build vendor target files ..."
	$(hide) if [ ! -d $(OUT_DIR) ]; then mkdir -p $(OUT_DIR); fi
	$(hide) rm -rf $(VENDOR_TARGET_DIR)
	$(hide) cp -r $(VENDOR_DIR) $(VENDOR_TARGET_DIR)
	$(hide) mv $(VENDOR_TARGET_DIR)/system $(VENDOR_TARGET_DIR)/SYSTEM
	$(hide) if [ -f $(OUT_DIR)/boot.img ]; then cp -r $(OUT_DIR)/boot.img $(VENDOR_TARGET_DIR)/IMAGES/boot.img; fi
	$(hide) if [ -f $(OUT_OBJ_BOOT)/RAMDISK/file_contexts.bin ]; then \
			cp -r $(OUT_OBJ_BOOT)/RAMDISK/file_contexts.bin $(VENDOR_TARGET_DIR)/META/file_contexts.bin; \
		fi
	$(hide) if [ -d $(PRJ_ROOT)/ROOT ]; then \
			rm -rf $(VENDOR_TARGET_DIR)/ROOT; \
			cp -a $(PRJ_ROOT)/ROOT $(VENDOR_TARGET_DIR); \
		fi
	$(hide) if [ -f $(VENDOR_TARGET_DIR)/ROOT/file_contexts.bin ]; then \
			echo ">> pack $(VENDOR_TARGET_DIR)/ROOT/file_contexts.bin ..."; \
			$(SEFCONTEXT_COMPILE_TOOL) -o $(VENDOR_TARGET_DIR)/ROOT/file_contexts.bin $(VENDOR_TARGET_DIR)/ROOT/file_contexts; \
			rm -r $(VENDOR_TARGET_DIR)/ROOT/file_contexts; \
			echo "<< pack $(VENDOR_TARGET_DIR)/ROOT/file_contexts.bin done"; \
			cp $(VENDOR_TARGET_DIR)/ROOT/file_contexts.bin $(VENDOR_TARGET_DIR)/META/file_contexts.bin; \
		fi
	$(hide) len=$$(grep -v "^#" $(VENDOR_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{print NF}' | head -1); \
		isNew=$$(grep -v "^#" $(VENDOR_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{if ($$2 == "/system"||$$2 == "/"){print "NEW"}}'); \
		if [ "x$$len" = "x5" ] && [ "x$$isNew" = "xNEW" ]; \
		then \
			sed -i '/^fstab_version[ \t]*=.*/d' $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
			echo "fstab_version=2" >> $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
		else \
			sed -i '/^fstab_version[ \t]*=.*/d' $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
			echo "fstab_version=1" >> $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
		fi;
	$(hide) if [ x"false" = x"$(strip $(USE_ASSERTIONS_IN_UPDATER_SCRIPT))" ]; then \
			echo "use_assertions=false" >> $(VENDOR_TARGET_DIR)/META/misc_info.txt; \
		fi
	$(hide) echo ">>> zip $(VENDOR_TARGET_ZIP) from $(VENDOR_TARGET_DIR) ..."
	$(hide) cd $(VENDOR_TARGET_DIR); zip -qry $(PRJ_ROOT)/$(VENDOR_TARGET_ZIP) *; cd - > /dev/null
	$(hide) echo "<<< zip $(VENDOR_TARGET_ZIP) from $(VENDOR_TARGET_DIR) done"
	$(hide) echo "<< build vendor target files done"

$(VENDOR_OTA_ZIP): $(VENDOR_TARGET_ZIP)
	$(hide) echo "> build vendor ota package ..."
	$(hide) if [ x"$(strip $(PRODUCE_BLOCK_BASED_OTA))" = x"false" ];then \
			$(TARGET_FILES_FROM_DEVICE) ota $(PRODUCE_IS_AB_UPDATE); \
		else \
			$(TARGET_FILES_FROM_DEVICE) ota_block $(PRODUCE_IS_AB_UPDATE); \
		fi;
	$(hide) echo "< build vendor ota package done"

###################### recovery link ########################
.PHONY: recovery_link
recovery_link: $(VENDOR_DIR)
	$(hide) echo "> recovery vendor linkinfo ..."
	$(hide) $(RECOVERY_LINK) $(VENDOR_DIR)/META/linkinfo.txt $(VENDOR_DIR);
	$(hide) echo "< recovery vendor linkinfo done"

###################### update file_system ########################
.PHONY: update_file_system_config
update_file_system_config: $(VENDOR_DIR)
	$(hide) echo "> update file system config info ..."
	$(hide) if [ ! -d $(OUT_DIR) ]; then mkdir -p $(OUT_DIR); fi
	$(hide) if [ ! -f $(OUT_DIR)/file_contexts.bin ]; then \
			if [ -f $(PRJ_BOOT_IMG_OUT)/RAMDISK/file_contexts.bin ]; then \
				if [ x"$(PRODUCE_IS_AB_UPDATE)" = x"true" ]; then \
					cp $(PRJ_ROOT)/ROOT/file_contexts.bin $(OUT_DIR)/file_contexts.bin; \
				else \
					cp $(PRJ_BOOT_IMG_OUT)/RAMDISK/file_contexts.bin $(OUT_DIR)/file_contexts.bin; \
				fi; \
			else \
				echo "get file_contexts.bin from phone ..."; \
				adb pull /file_contexts.bin $(OUT_DIR)/file_contexts.bin; \
				echo -n ""; \
			fi; \
		fi;
	$(hide) if [ -f $(OUT_DIR)/file_contexts.bin ]; then \
			cd $(VENDOR_DIR); zip -qry $(PRJ_ROOT)/$(OUT_DIR)/vendor_system.zip system; cd - > /dev/null; \
			zipinfo -1 $(OUT_DIR)/vendor_system.zip \
				| $(PORT_ROOT)/build/tools/bin/fs_config -C -D $(VENDOR_SYSTEM) -S $(OUT_DIR)/file_contexts.bin \
				| sort > $(VENDOR_META)/filesystem_config.txt; \
			rm $(PRJ_ROOT)/$(OUT_DIR)/vendor_system.zip; \
			if [ x"$(PRODUCE_IS_AB_UPDATE)" = x"true" ]; then \
				cd $(VENDOR_DIR)/ROOT; zip -qry $(PRJ_ROOT)/$(OUT_DIR)/vendor_root.zip .; cd - > /dev/null; \
				zipinfo -1 $(OUT_DIR)/vendor_root.zip \
					| $(PORT_ROOT)/build/tools/bin/fs_config -C -D $(VENDOR_DIR)/ROOT -S $(OUT_DIR)/file_contexts.bin \
					| sort > $(VENDOR_META)/root_filesystem_config.txt; \
				rm $(PRJ_ROOT)/$(OUT_DIR)/vendor_root.zip; \
			fi; \
		else \
			echo "ERROR: Please ensure adb can find your device or can adb pull file_contexts.bin and then rerun this script!!"; \
			echo "Maby you can get the file_contexts.bin from phone or ota.zip and copy to devices/$(PRJ_NAME)/$(OUT_DIR)"; \
			echo ""; \
		fi;
	$(hide) echo "< update file system config info done"
