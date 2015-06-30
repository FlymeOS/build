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

newproject: prepare-vendor prepare-vendor-boot prepare-vendor-recovery decodefile
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
	$(hide) $(TARGET_FILES_FROM_DEVICE) target
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

$(VENDOR_TARGET_ZIP): $(VENDOR_RECOVERY_FSTAB)
	$(hide) echo ">> build vendor target files ..."
	$(hide) if [ ! -d $(OUT_DIR) ]; then mkdir -p $(OUT_DIR); fi
	$(hide) rm -rf $(VENDOR_TARGET_DIR)
	$(hide) cp -r $(VENDOR_DIR) $(VENDOR_TARGET_DIR)
	$(hide) echo ">>> recover the link files for $(VENDOR_TARGET_DIR) ..."
	$(hide) $(RECOVER_LINK) $(VENDOR_TARGET_DIR)/META/linkinfo.txt $(VENDOR_TARGET_DIR);
	$(hide) echo "<<< recover the link files for $(VENDOR_TARGET_DIR) done"
	$(hide) mv $(VENDOR_TARGET_DIR)/system $(VENDOR_TARGET_DIR)/SYSTEM
	$(hide) rm -rf $(VENDOR_TARGET_DIR)/BOOTABLE_IMAGES/ $(VENDOR_TARGET_DIR)/BOOT
	$(hide) len=$$(grep -v "^#" $(VENDOR_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{print NF}' | head -1); \
		isNew=$$(grep -v "^#" $(VENDOR_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{if ($$2 == "/system"){print "NEW"}}'); \
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
	$(hide) $(TARGET_FILES_FROM_DEVICE) ota
	$(hide) echo "< build vendor ota package done"
