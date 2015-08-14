# use for preparing board's resource from BOARD_DIR

$(PREPARE_SOURCE):
	$(hide) echo "> Prepare board sources in $(BOARD_DIR) ...";
	$(hide) if [ ! -e $(BOARD_DIR) ];then mkdir -p $(BOARD_DIR);fi
	$(hide) cp -rf $(BOARD_RELEASE)/* $(BOARD_DIR)
	$(hide) if [ -d $(BOARD_DIR)/SYSTEM ];then mv $(BOARD_DIR)/SYSTEM $(BOARD_DIR)/system;fi
ifneq ($(THEME_RES),)
	$(hide) unzip -q -o $(THEME_RES) -d $(BOARD_DIR)/theme_full_res
endif
	$(hide) $(PORT_CUSTOM_BOARD_ZIP) $(BOARD_DIR) $(DENSITY)
	$(hide) if [ ! -d $(BOARD_FRAMEWORK) ] \
		|| [ ! -d $(BOARD_SYSTEM)/lib ] \
		|| [ ! -d $(BOARD_SYSTEM)/app ];then \
			echo "< ERROR: source is not complete, please check."; \
			exit 1; \
		fi;
	$(hide) if [ -f $(BOARD_DIR)/boot.img ]; then \
			boot_image=$(BOARD_DIR)/boot.img; \
		else  \
			if [ -f $(BOARD_DIR)/BOOTABLE_IMAGES/boot.img ]; then \
				boot_image=$(BOARD_DIR)/BOOTABLE_IMAGES/boot.img; \
			fi; \
		fi; \
		if [ "x$$boot_image" != "x" -a ! -f $(BOARD_DIR)/BOOT/RAMDISK/init ];then \
			echo ">> unpack $$boot_image to $(BOARD_DIR)/BOOT ..."; \
			rm -rf $(BOARD_DIR)/BOOT; \
			$(UNPACK_BOOT_PY) $$boot_image $(BOARD_DIR)/BOOT; \
			rm -rf $(OUT_OBJ_BOOT)/boot.img; \
			echo "<< unpack $$boot_image to $(BOARD_DIR)/BOOT done"; \
		fi;
	$(hide) if [ -f $(BOARD_DIR)/recovery.img ]; then \
			recovery_image=$(BOARD_DIR)/recovery.img; \
		else  \
			if [ -f $(BOARD_DIR)/BOOTABLE_IMAGES/recovery.img ]; then \
				recovery_image=$(BOARD_DIR)/BOOTABLE_IMAGES/recovery.img; \
			fi; \
		fi; \
		if [ "x$$recovery_image" != "x" -a ! -f $(BOARD_DIR)/RECOVERY/RAMDISK/init ];then \
			echo ">> unpack $$recovery_image to $(BOARD_DIR)/RECOVERY ..."; \
			rm -rf $(BOARD_DIR)/RECOVERY; \
			$(UNPACK_BOOT_PY) $$recovery_image $(BOARD_DIR)/RECOVERY; \
			rm -rf $(OUT_OBJ_BOOT)/recovery.img; \
			echo "<< unpack $$recovery_image to $(BOARD_DIR)/RECOVERY done"; \
		fi;
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@
	$(hide) echo "< Prepare board sources in $(BOARD_DIR) done";
	$(hide) echo " "
