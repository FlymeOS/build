# use for preparing board's resource from board.zip

$(BOARD_ZIP): tempDir := $(shell mktemp -u)
$(BOARD_ZIP):
	@ echo "> Prepare board.zip ..."
	$(hide) rm -rf $(BOARD_ZIP)
	$(hide) mkdir -p $(tempDir)
	$(hide) cp -rf $(BOARD_RELEASE)/* $(tempDir)
	$(hide) $(PORT_CUSTOM_BOARD_ZIP) $(tempDir) $(DENSITY)
	@ echo ">> zip $@ from $(BOARD_RELEASE) ..."
	$(hide) cd $(tempDir) 2>&1 > /dev/null && zip board.zip * -rqy && cd - 2>&1 > /dev/null
	@ echo "<< zip $@ from $(BOARD_RELEASE) done"
	$(hide) mkdir -p `dirname $@`
	$(hide) mv $(tempDir)/board.zip $@
	$(hide) rm -rf $(tempDir)
	@ echo "< Prepare board.zip done!"

$(PREPARE_SOURCE): deodex_thread_num := $(shell echo "$(MAKE)" | awk '{print $$2}')
$(PREPARE_SOURCE): $(BOARD_ZIP)
	$(hide) echo "> Prepare board sources ...";
	$(hide) echo ">> Normalize the OAT package $(BOARD_ZIP) ..."
	$(hide) $(OTA_NORMALIZE) --input $(BOARD_ZIP)
	$(hide) if [ -f $(BOARD_ZIP).std.zip ];then \
			mv $(BOARD_ZIP).std.zip $(BOARD_ZIP); \
		else \
			echo "<< ERROR: normalize $(BOARD_ZIP) failed!!";\
			exit 1;\
		fi;
	$(hide) echo "<< Normalize the OAT package $(BOARD_ZIP) done"
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)
	$(hide) echo ">> unzip $(BOARD_ZIP) to $(BOARD_DIR) ..."
	$(hide) unzip -q -o $(BOARD_ZIP) -d $(BOARD_DIR);
	$(hide) if [ -d $(BOARD_DIR)/SYSTEM ];then mv $(BOARD_DIR)/SYSTEM $(BOARD_DIR)/system;fi
ifneq ($(THEME_RES),)
	$(hide) unzip -q -o $(THEME_RES) -d $(BOARD_DIR)/theme_full_res
endif
	$(hide) echo "<< unzip $(BOARD_ZIP) to $(BOARD_DIR) done"
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
	$(hide) echo "< Prepare board sources done";
	$(hide) echo " "
