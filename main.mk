# main.mk

#$(info # ------------------------------------------------------------------)


####################  custom #########################
ifneq ($(wildcard $(PORT_BUILD)/custom/defines.mk),)
include $(PORT_BUILD)/custom/defines.mk
endif

include $(PORT_BUILD)/locals.mk
include $(PORT_BUILD)/defines.mk

include $(PORT_BUILD)/configs/board_default.mk
include $(PORT_BUILD)/configs/vendor_default.mk

# include the mk after board/xxx/rom/ for different base
$(foreach mk, \
	$(strip $(wildcard $(PORT_ROOT/board/$(BOARD_BASE_DEVICE)/rom))), \
	$(eval include $(mk)))

######################  ota ##########################
.PHONY: target-files framework-res bootimage recoveryimage
.PHONY: otapackage ota fullota

ifeq ($(strip $(wildcard $(BOARD_SYSTEM))),)
#$(info # no source directory, need $(PREPARE_SOURCE))
ota fullota otapackage: check-project $(PREPARE_SOURCE)
else
ota fullota otapackage: check-project
endif

ota fullota otapackage:
	$(hide) cd $(PRJ_ROOT) > /dev/null
	$(hide) echo "> build |target-files|PREBUILT,OTA,META,SYSTEM| ..."
	$(hide) echo ">> generate |target-files|PREBUILT| ..."
	$(hide) $(MAKE) ota-files-zip
	@echo "=========================================================================="
	@echo "Recommend Commands:                                                       "
	@echo "   make otadiff => build an Incremental OTA Package, with preparing       "
	@echo "         target_files.zip of previous version in current directory.       "
	@echo "   make otadiff PRE=xx/xx/target_files_xx.zip => specify previous package."
ifeq ($(strip $(PRODUCE_BLOCK_BASED_OTA)),false)
	@echo "   make otadiff PRE=xx/xx/ota_xx.zip => specify previous ota package.     "
endif
	@echo "=========================================================================="

.PHONY: ota.phone
ota.phone: ota_path := $(shell if [ -f $(PRJ_SAVED_OTA_NAME) ];then cat $(PRJ_SAVED_OTA_NAME); fi)
ota.phone:
	@echo "* Install ota package to device ..."
	$(hide) $(FLASH_OTA_TO_DEVICE) $(ota_path)

ifeq ($(strip $(WITH_DEXPREOPT)),true)
NEED_SIGNED_TARGET_ZIP := $(PRJ_TARGET_FILE_ODEX)
else
NEED_SIGNED_TARGET_ZIP := $(PRJ_OUT_TARGET_ZIP)
endif

ifeq ($(strip $(WITH_SIGN)),true)
OUT_TARGET_ZIP := $(PRJ_SIGNED_TARGET_FILE)
else
OUT_TARGET_ZIP := $(NEED_SIGNED_TARGET_ZIP)
endif

################# check-project ######################
.PHONY: check-project
check-project:
	$(hide) echo "> Check project $(PRJ_NAME) ..."
	$(hide) if [ ! -f $(PRJ_ROOT)/Makefile ] && [ ! -f $(PRJ_ROOT)/makefile ];then \
			echo "< ERROR: $(PRJ_ROOT)/Makefile doesn't exist!!"; \
			exit 1; \
		fi
	$(hide) echo "< Check project $(PRJ_NAME) done"

####################### clean #########################
CLEAN_TARGETS += clean-out 

.PHONY: clean-out
clean-out:
	$(hide) if [ -d $(OUT_DIR) ];then \
			filelist=$$(ls $(OUT_DIR)/*.zip 2> /dev/null | egrep "$(OUT_DIR)/flyme.*\.zip|$(OUT_DIR)/target.*\.zip" | tr "\n" " "); \
			if [ x"$$filelist" != x"" ];then \
				filename=`echo $$filelist | sed 's#$(OUT_DIR)/##g'`; \
				echo "> Backup files to $(HISTORY_DIR) ..."; \
				echo "  $$filename"; \
				mkdir -p $(HISTORY_DIR); \
				mv $$filelist $(HISTORY_DIR) > /dev/null; \
				echo "< Backup files to $(HISTORY_DIR) done"; \
			fi; \
			echo "> remove $(OUT_DIR)/ ..."; \
			rm -rf $(OUT_DIR); \
			echo "< remove $(OUT_DIR)/ done"; \
		fi

CLEAN_TARGETS += clean-source

CLEAN_SOURCE_REMOVE_TARGETS := $(patsubst %,$(BOARD_DIR)/%,$(filter-out $(notdir $(BOARD_ZIP) $(BOARD_LAST_ZIP) $(THEME_RES)) \
                                    timestamp,$(shell if [ -d $(BOARD_DIR) ]; then ls $(BOARD_DIR); fi)))
.PHONY: clean-source
clean-source:
	$(hide) echo "> remove some files in $(BOARD_DIR) ..."
	$(hide) rm -rf $(CLEAN_SOURCE_REMOVE_TARGETS)
	$(hide) echo "< remove some files in $(BOARD_DIR) done"

clean-board-zip:
	$(hide) echo "> remove $(BOARD_DIR) ...";
	$(hide) rm -rf $(BOARD_DIR);
	$(hide) echo "< remove $(BOARD_DIR) done";

.PHONY: clean-autopatch
clean-autopatch:
	$(hide) echo "> remove $(PRJ_ROOT)/autopatch ...";
	$(hide) rm -rf $(PRJ_ROOT)/autopatch;
	$(hide) echo "< remove $(PRJ_ROOT)/autopatch done";

################### boot recovery ######################
include $(PORT_BUILD)/boot_recovery.mk

TARGET_FILES_SYSTEM += bootimage recoveryimage

################### newproject #########################
include $(PORT_BUILD)/newproject.mk

################ prepare board's source ################
include $(PORT_BUILD)/prepare_board.mk

#################   prebuilt   #########################
# get all of the files from source/system
ALL_BOARD_FILES := \
    $(strip $(patsubst $(BOARD_SYSTEM_FOR_POS)/%,%,\
        $(strip $(call get_all_files_in_dir,$(BOARD_SYSTEM_FOR_POS)))))

# get all of the files from vendor/vendor_files
ALL_VENDOR_FILES := \
    $(strip $(patsubst $(VENDOR_SYSTEM)/%,%,\
        $(strip $(call get_all_files_in_dir,$(VENDOR_SYSTEM)))))

# get the project modified app and jars, remove them from prebuilt list
PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,app/%.apk,\
        $(vendor_saved_apps) \
        $(vendor_modify_apps) \
        $(board_modify_apps))))

PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,framework/%.apk,\
        $(vendor_modify_apps) $(board_modify_apps))))

PRJ_CUSTOM_TARGET += $(sort $(strip \
    $(patsubst %,framework/%.jar,\
        $(vendor_modify_jars) \
        $(board_modify_jars))))

PRJ_CUSTOM_TARGET += $(sort framework/framework-res.apk)
PRJ_CUSTOM_TARGET += $(sort build.prop)

BOARD_PRJ_CUSTOM_TARGET := $(PRJ_CUSTOM_TARGET)
$(call resetPosition,BOARD_PRJ_CUSTOM_TARGET,$(BOARD_SYSTEM_FOR_POS))
$(call resetPosition,PRJ_CUSTOM_TARGET,$(VENDOR_SYSTEM))
PRJ_CUSTOM_TARGET := $(strip $(PRJ_CUSTOM_TARGET) $(BOARD_PRJ_CUSTOM_TARGET))

# add the vendor prebuilt apps
VENDOR_PREBUILT_APPS := $(patsubst %,app/%.apk,$(vendor_saved_apps))
$(call resetPosition,VENDOR_PREBUILT_APPS,$(VENDOR_SYSTEM))

include $(PORT_BUILD)/prebuilt.mk

###### get all of the framework resources apks #########
BOARD_FRAMEWORK_APKS := $(patsubst %,$(BOARD_SYSTEM)/%, \
    $(strip $(sort $(filter framework/%.apk, $(ALL_BOARD_FILES)))))

VENDOR_FRAMEWORK_APKS := $(patsubst %,$(VENDOR_SYSTEM)/%, \
    $(strip $(sort $(filter framework/%.apk, $(ALL_VENDOR_FILES)))))

FRAMEWORK_APKS_TARGETS := $(patsubst %,$(OUT_SYSTEM)/%,\
    $(strip $(sort $(filter framework/%.apk, framework/flyme-res/flyme-res.apk $(ALL_VENDOR_FILES)))))


$(BOARD_FRAMEWORK_APKS): $(PREPARE_SOURCE)

$(IF_BOARD_RES): $(BOARD_FRAMEWORK_APKS) $(PREPARE_SOURCE)
	$(hide) echo ">>> apktool if(install framework): board ..."
	$(hide) $(call apktool_if_board,$(BOARD_FRAMEWORK))
	$(hide) $(call apktool_if_board_modify,$(BOARD_FRAMEWORK))
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@
	$(hide) echo "<<< apktool if(install framework): board done"

$(IF_VENDOR_RES): $(VENDOR_FRAMEWORK_APKS)
	$(hide) echo ">>> apktool if(install framework): vendor ..."
	$(hide) $(call apktool_if_vendor,$(VENDOR_FRAMEWORK))
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@
	$(hide) echo "<<< apktool if(install framework): vendor done"

$(IF_MERGED_RES): $(FRAMEWORK_APKS_TARGETS)
	$(hide) echo ">>> apktool if(install framework): merged ..."
	$(hide) $(call apktool_if_merged,$(OUT_SYSTEM_FRAMEWORK))
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@
	$(hide) echo "<<< apktool if(install framework): merged done"

BOARD_FRW_APK_NAMES :=
VENDOR_FRW_APK_NAMES :=
MERGED_FRW_APK_NAMES :=

$(foreach frw_res, $(BOARD_FRAMEWORK_APKS),   $(eval BOARD_FRW_APK_NAMES  += $(call getBaseName, $(frw_res))))
$(foreach frw_res, $(VENDOR_FRAMEWORK_APKS),  $(eval VENDOR_FRW_APK_NAMES += $(call getBaseName, $(frw_res))))
$(foreach frw_res, $(FRAMEWORK_APKS_TARGETS), $(eval MERGED_FRW_APK_NAMES += $(call getBaseName, $(frw_res))))

$(foreach frw_res, $(MERGED_FRW_APK_NAMES), \
	$(eval $(if $(filter 3, $(words $(filter $(frw_res), $(BOARD_FRW_APK_NAMES) $(VENDOR_FRW_APK_NAMES) $(MERGED_FRW_APK_NAMES)))),BOTH_OWN_RES += $(frw_res))))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(BOARD_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_BOARD)/$(frw_res)) \
	$(eval $(call decode_board,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(VENDOR_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_VENDOR)/$(frw_res)) \
	$(eval $(call decode_vendor,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

$(foreach frw_res, $(BOTH_OWN_RES), \
	$(eval frw_res_apk := $(OUT_SYSTEM_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_MERGED)/$(frw_res)) \
	$(eval $(call decode_merged,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))

ifeq ($(ALL_FRW_NAME_TO_ID),true)
NOT_BOTH_OWN_RES := $(filter-out $(BOTH_OWN_RES), $(MERGED_FRW_APK_NAMES))

$(foreach frw_res, $(NOT_BOTH_OWN_RES), \
	$(eval frw_res_apk := $(OUT_SYSTEM_FRAMEWORK)/$(frw_res).apk) \
	$(eval targetDir := $(FRW_RES_DECODE_MERGED)/$(frw_res)) \
	$(eval $(call decode_merged,$(frw_res_apk),$(targetDir))) \
	$(eval PREPARE_FRW_RES_TARGET += $(targetDir)/apktool.yml))
endif

.IGNORE: $(PREPARE_FRW_RES_TARGET)

$(PREPARE_FRW_RES_JOB): $(PREPARE_FRW_RES_TARGET)
	$(hide) for frw_res_target in $(PREPARE_FRW_RES_TARGET); do \
			if [ ! -e $$frw_res_target ];then \
				echo "<<< WARNING: Failed to create $$frw_res_target, because of decode failure"; \
				mkdir -p `dirname $$frw_res_target`; \
				touch $$frw_res_target; \
			fi \
		done
	$(hide) mkdir -p `dirname $@`
	$(hide) touch $@

################# build.prop ###########################
include $(PORT_BUILD)/build.prop.mk


################# sepolicy #############################
include $(PORT_BUILD)/sepolicy/sepolicy.mk

################ framework-res #########################

# generate the merged_update.txt mereged_none.txt merged_add.txt
.PHONY: generate-merged-txts
MERGED_TXTS := $(MERGE_NONE_TXT) $(MERGE_ADD_TXT)
$(MERGED_TXTS): $(MERGE_UPDATE_TXT)
	@ echo "" > /dev/null

$(MERGE_UPDATE_TXT): TXT_OUT_DIR := $(OUT_OBJ_RES)
$(MERGE_UPDATE_TXT): TMP_OUT_DIR := $(OUT_OBJ_RES)/tmp_txts
$(MERGE_UPDATE_TXT): TMP_UPDATE := $(OUT_OBJ_RES)/tmp_update.txt
$(MERGE_UPDATE_TXT): TMP_NONE := $(OUT_OBJ_RES)/tmp_none.txt
$(MERGE_UPDATE_TXT): OTHER_FRW_RES := $(filter-out framework-res, $(BOTH_OWN_RES))
$(MERGE_UPDATE_TXT): $(PREPARE_FRW_RES_JOB)
	$(hide) echo ">>> generate the merged_update.txt ..."
	$(hide) mkdir -p $(TMP_OUT_DIR)
	$(hide) $(DIFFMAP_TOOL) -map $(VENDOR_PUBLIC_XML) \
		$(MERGED_PUBLIC_XML) $(BOARD_PUBLIC_XML) $(TMP_OUT_DIR) > /dev/null
	$(hide) for frw_res in $(OTHER_FRW_RES); do \
			if [ -f $(FRW_RES_DECODE_MERGED)/$$frw_res/res/values/public.xml ] && \
			   [ -f $(FRW_RES_DECODE_BOARD)/$$frw_res/res/values/public.xml ]; then \
				$(GENMAP_TOOL) -map $(FRW_RES_DECODE_MERGED)/$$frw_res/res/values/public.xml \
						$(FRW_RES_DECODE_BOARD)/$$frw_res/res/values/public.xml \
						$(TMP_UPDATE) $(TMP_NONE); \
				if [ -f $(TMP_UPDATE) ]; then \
					cat $(TMP_UPDATE) >> $(TMP_OUT_DIR)/merge_update.txt; \
				fi; \
				rm -rf $(TMP_UPDATE) $(TMP_NONE); \
			fi; \
		done
	$(hide) mv $(TMP_OUT_DIR)/* $(TXT_OUT_DIR)
	$(hide) rm -rf $(TMP_OUT_DIR)
	$(hide) echo "<<< generate the merged_update.txt done"

generate-merged-txts: $(MERGE_UPDATE_TXT)
	@ echo "" > /dev/null

CLEAN_TARGETS += clean-merged-txts
.PHONY: clean-merged-txts
clean-merged-txts: CLEAN_MERGED_TXTS := $(MERGED_TXTS) $(MERGE_UPDATE_TXT)
clean-merged-txts:
	$(hide) rm -rf $(CLEAN_MERGED_TXTS);

# get the sources files of overlay and vendor framework-res
# get project overlay
PRJ_FRAMEWORK_OVERLAY_SOURCES += $(sort $(strip $(call get_all_files_in_dir, $(PRJ_FRAMEWORK_OVERLAY))))
FRAMEWORK_RES_SOURCE += $(PRJ_FRAMEWORK_OVERLAY_SOURCES)

# get project for board
BOARD_OVERLAY_SOURCE := $(sort $(strip $(call get_all_files_in_dir, $(BOARD_FRAMEWORK_OVERLAY))))
FRAMEWORK_RES_SOURCE += $(BOARD_OVERLAY_SOURCE)
FRAMEWORK_RES_SOURCE += $(sort $(strip $(call get_all_files_in_dir, $(VENDOR_FRAMEWORK_RES_OUT))))

# add framework-res to TARGET_FILES_SYSTEM
TARGET_FILES_SYSTEM += framework-res

# add framework-res.apk to SIGN_APPS
# means framework-res will be signed and zipalign
SIGN_APPS += \
    $(OUT_OBJ_FRAMEWORK)/framework-res.apk:$(OUT_SYSTEM_FRAMEWORK)/framework-res.apk

clean-framework-res: remove_targets += $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
# use aapt to generate the framework-res.apk
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: minSdkVersion := $(shell $(call getMinSdkVersionFromApktoolYml,\
									$(VENDOR_FRAMEWORK_RES_OUT)/apktool.yml))
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: targetSdkVersion := $(shell $(call getTargetSdkVersionFromApktoolYml,\
									$(VENDOR_FRAMEWORK_RES_OUT)/apktool.yml))
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: OUT_OBJ_FRAMEWORK_RES := $(OUT_OBJ_FRAMEWORK)/framework-res
$(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp: $(FRAMEWORK_RES_SOURCE) 
	$(hide) echo ">>> build |target-files|SYSTEM|framework-res.apk| ..."
	$(hide) rm -rf $(OUT_OBJ_FRAMEWORK_RES)
	$(hide) mkdir -p $(OUT_OBJ_FRAMEWORK_RES)
	$(hide) cp -rf $(BOARD_FRAMEWORK_OVERLAY) $(OUT_OBJ_FRAMEWORK_RES)/board-res-overlay
	$(hide) $(call formatOverlay,$(OUT_OBJ_FRAMEWORK_RES)/board-res-overlay)
	$(hide) $(if $(PRJ_FRAMEWORK_OVERLAY_SOURCES), \
				cp -rf $(PRJ_FRAMEWORK_OVERLAY) $(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay; \
				$(call formatOverlay,$(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay);,)
	$(hide) cp $(VENDOR_FRAMEWORK_RES_OUT)/AndroidManifest.xml $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml;
	$(hide) sed -i 's/android:versionName[ ]*=[ ]*"[^\"]*"//g' $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml;
	$(hide) echo ">>>> use AAPT to build multiple resource directory ..."
	$(AAPT) package -u -x -z \
		$(if $(filter false,$(REDUCE_RESOURCES)),,$(addprefix -c , $(PRIVATE_PRODUCT_AAPT_CONFIG)) \
						          $(addprefix --preferred-density , $(PRIVATE_PRODUCT_AAPT_PREF_CONFIG))) \
		$(if $(minSdkVersion),$(addprefix --min-sdk-version , $(minSdkVersion)),) \
		$(if $(targetSdkVersion),$(addprefix --target-sdk-version , $(targetSdkVersion)),) \
		$(if $(VERSION_NUMBER),$(addprefix --version-name ,$(VERSION_NUMBER)),) \
		-M $(OUT_OBJ_FRAMEWORK_RES)/AndroidManifest.xml \
		-A $(VENDOR_FRAMEWORK_RES_OUT)/assets \
		$(if $(PRJ_FRAMEWORK_OVERLAY_SOURCES),-S $(OUT_OBJ_FRAMEWORK_RES)/project-res-overlay,)\
		-S $(OUT_OBJ_FRAMEWORK_RES)/board-res-overlay \
		-S $(VENDOR_FRAMEWORK_RES_OUT)/res \
		-F $@ 1>/dev/null
	$(hide) echo "<<<< use AAPT to build multiple resource directory done"


$(OUT_OBJ_FRAMEWORK)/framework-res.apk: tmpResDir := $(shell mktemp -u $(OUT_OBJ_FRAMEWORK)/framework-res.XXX)

ifneq ($(strip $(NOT_CUSTOM_FRAMEWORK-RES)),true)
$(OUT_OBJ_FRAMEWORK)/framework-res.apk: $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
	$(hide) mkdir -p $(tmpResDir)
	$(hide) $(APKTOOL) d -f $< -o $(tmpResDir)
	$(hide) $(call custom_app,framework-res,$(tmpResDir))
	$(hide) $(APKTOOL) b $(tmpResDir) -o $@
	$(hide) rm -rf $(tmpResDir)
	$(hide) echo "<<< build |target-files|SYSTEM|framework-res.apk| done"
else
$(OUT_OBJ_FRAMEWORK)/framework-res.apk: $(OUT_OBJ_FRAMEWORK)/framework-res.apk.tmp
	$(hide) cp $< $@
endif

# define the rule to make framework-res
framework-res: $(OUT_SYSTEM_FRAMEWORK)/framework-res.apk generate-merged-txts
	$(hide) echo "* build framework-res out ==> $(OUT_SYSTEM_FRAMEWORK)/framework-res.apk"
	$(hide) echo " "

############## framework-res end #######################

############## need update res id's apks ###############

# remove the files which doesn't exist!!
BOARD_MODIFY_RESID_FILES := $(sort $(strip $(filter $(ALL_BOARD_FILES),$(BOARD_MODIFY_RESID_FILES))))

# build board_modify_apps
BOARD_MODIFY_APPS := $(strip $(patsubst %,app/%.apk,$(board_modify_apps)))
$(call resetPosition,BOARD_MODIFY_APPS,$(BOARD_SYSTEM_FOR_POS))
#$(info # BOARD_MODIFY_APPS:$(BOARD_MODIFY_APPS))
$(foreach apk,$(BOARD_MODIFY_APPS),\
    $(eval $(call board_modify_apk_build,$(PRJ_ROOT)/$(call getBaseName,$(apk)),$(apk))))

BOARD_MODIFY_RESID_FILES := $(filter-out $(PRJ_CUSTOM_TARGET) $(BOARD_REMOVE_APP_FILES),$(BOARD_MODIFY_RESID_FILES))

$(foreach apk,$(BOARD_MODIFY_RESID_FILES),\
    $(eval AAPT_BUILD_TARGET:=$(BOARD_SYSTEM)/$(apk)) \
    $(if $(strip $(filter %.jar,$(apk))),\
         $(eval SIGN_JARS += $(OUT_OBJ_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)),\
         $(eval SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk))\
         $(if $(filter true,$(REDUCE_RESOURCES)),\
               $(if $(filter framework/%,$(apk)),,\
                   $(eval $(call aapt_build_board_apk,$(BOARD_SYSTEM)/$(apk),$(OUT_OBJ_SYSTEM)/$(apk).aapt))\
                   $(eval AAPT_BUILD_TARGET := $(OUT_OBJ_SYSTEM)/$(apk).aapt)),))\
    $(if $(strip $(filter $(REDUCE_RESOURCES_EXCLUDE_APPS),$(apk))),$(eval AAPT_BUILD_TARGET:=$(BOARD_SYSTEM)/$(apk)),)\
    $(eval $(call board_modify_resid_template,$(apk)))\
    $(eval AAPT_BUILD_TARGET :=))

################## vendor_modify_apps ##################
#$(info # vendor_modify_apps:$(vendor_modify_apps))

$(foreach apk,$(vendor_modify_apps),\
    $(eval apkPos := $(call posOfApp,app/$(apk).apk,$(VENDOR_SYSTEM))) \
    $(if $(wildcard $(PRJ_ROOT)/$(apk)/smali), \
           $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))), \
           $(if $(call is_framework_apk,$(PRJ_ROOT)/$(apk)/apktool.yml), \
               $(eval $(call framework_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))), \
               $(eval $(call vendor_modify_apk_build,$(PRJ_ROOT)/$(apk),$(apkPos))) \
           ) \
    ) \
)

################### need signed apks ###################
# remove the files which doesn't exist!!
BOARD_SIGNED_APPS := $(sort $(strip $(filter $(ALL_BOARD_FILES),$(BOARD_SIGNED_APPS))))
BOARD_SIGNED_APPS := $(filter-out $(PRJ_CUSTOM_TARGET),$(BOARD_SIGNED_APPS))
$(call resetPositionApp,board_remove_apps,$(BOARD_SYSTEM_FOR_POS))
BOARD_SIGNED_APPS := $(filter-out $(board_remove_apps),$(BOARD_SIGNED_APPS))

PRIVATE_REDUCE_RESOURCES_EXCLUDE_APPS := $(filter $(REDUCE_RESOURCES_EXCLUDE_APPS),$(BOARD_SIGNED_APPS))

BOARD_SIGNED_FR_APPS  := $(filter framework/%,$(BOARD_SIGNED_APPS)) $(PRIVATE_REDUCE_RESOURCES_EXCLUDE_APPS)
BOARD_SIGNED_APP_APPS := $(filter-out $(BOARD_SIGNED_FR_APPS),$(BOARD_SIGNED_APPS))

# add the board's sign apk to SIGN_APPS
ifeq ($(strip $(REDUCE_RESOURCES)),true)
$(foreach apk,$(BOARD_SIGNED_APP_APPS),\
    $(eval SIGN_APPS += $(OUT_OBJ_SYSTEM)/$(apk).aapt:$(OUT_SYSTEM)/$(apk)) \
	$(eval $(call aapt_build_board_apk,$(BOARD_SYSTEM)/$(apk),$(OUT_OBJ_SYSTEM)/$(apk).aapt)))
else
$(foreach apk,$(BOARD_SIGNED_APP_APPS),\
    $(eval SIGN_APPS += $(BOARD_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))
endif

$(foreach apk,$(BOARD_SIGNED_FR_APPS),\
    $(eval SIGN_APPS += $(BOARD_SYSTEM)/$(apk):$(OUT_SYSTEM)/$(apk)))

############# board_modify_jars ########################
$(foreach jar,$(board_modify_jars),\
    $(eval $(call board_modify_jar_build,$(PRJ_ROOT)/$(jar).jar.out,framework/$(jar).jar)))

############# vendor_modify_jars #######################
$(foreach jar,$(vendor_modify_jars),\
    $(eval $(call vendor_modify_jar_build,$(PRJ_ROOT)/$(jar).jar.out,framework/$(jar).jar)))

################ process jars ##########################

#$(info # SIGN_JARS:$(SIGN_JARS))
$(foreach jar_pair,$(SIGN_JARS),\
    $(eval src_jar := $(call word-colon,1,$(jar_pair)))\
    $(eval dst_jar := $(call word-colon,2,$(jar_pair)))\
    $(eval $(call sign_jar,$(src_jar),$(dst_jar))))

.PHONY: sign-jars
TARGET_FILES_SYSTEM += sign-jars
sign-jars: $(SIGN_JAR_TARGETS)
#$(info # SIGN_JAR_TARGETS:$(SIGN_JAR_TARGETS))

########## signed apk with testkey #####################
#$(info # SIGN_APPS:$(SIGN_APPS))

$(foreach app_pair,$(SIGN_APPS),\
    $(eval src_apk := $(call word-colon,1,$(app_pair)))\
    $(eval dst_apk := $(call word-colon,2,$(app_pair)))\
    $(eval $(call sign_apk_with_apkcerts,$(src_apk),$(dst_apk))))

.PHONY: sign-apps
TARGET_FILES_SYSTEM += sign-apps
sign-apps: $(SIGN_APP_TARGETS)

################### META ###############################
$(OUT_META)/filesystem_config.txt: $(OUT_OBJ_META)/filesystem_config.txt
$(OUT_META)/filesystem_config.txt: target-files-system
	$(hide) echo ">>> generate |target-files|META|filesystem_config.txt| ...";
	$(hide) $(UPDATE_FILE_SYSTEM) $(OUT_OBJ_META)/filesystem_config.txt $(OUT_SYSTEM);
	$(hide) mkdir -p $(OUT_META);
	$(hide) cp $(OUT_OBJ_META)/filesystem_config.txt $(OUT_META)/filesystem_config.txt;
	$(hide) echo "<<< generate |target-files|META|filesystem_config.txt| done";

$(OUT_OBJ_META)/filesystem_config.txt: $(VENDOR_META)/filesystem_config.txt
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide)	$(FILE_UNION) $(VENDOR_META)/filesystem_config.txt $(BOARD_META)/filesystem_config.txt $(OUT_OBJ_META)/filesystem_config.txt;

$(OUT_OBJ_META)/misc_info.txt: $(VENDOR_META)/misc_info.txt
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) cp $< $@

$(OUT_META)/misc_info.txt: $(OUT_OBJ_META)/misc_info.txt $(OUT_RECOVERY_FSTAB)
	$(hide) echo ">>> generate |target-files|META|misc_config.txt| ...";
	$(hide) extensions_path=$$(cat $(OUT_OBJ_META)/misc_info.txt | grep "tool_extensions=.\+" | grep -v "tool_extensions="); \
		if [ -d "$(PRJ_ROOT)/$$extensions_path" -o -f "$(PRJ_ROOT)/$$extensions_path" ];then \
			sed -i '/tool_extensions/d' $<; \
			echo "tool_extensions=$(PRJ_ROOT)/$$extensions_path" >> $<; \
		fi
	$(hide) len=$$(grep -v "^#" $(OUT_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{print NF}' | head -1); \
		isNew=$$(grep -v "^#" $(OUT_RECOVERY_FSTAB) | egrep "ext|emmc|vfat|yaffs" | awk '{if ($$2 == "/system"){print "NEW"}}'); \
		if [ "x$$len" = "x5" ] && [ "x$$isNew" = "xNEW" ]; \
		then \
			sed -i '/^fstab_version[ \t]*=.*/d' $(OUT_OBJ_META)/misc_info.txt; \
			echo "fstab_version=2" >> $(OUT_OBJ_META)/misc_info.txt; \
		else \
			sed -i '/^fstab_version[ \t]*=.*/d' $(OUT_OBJ_META)/misc_info.txt; \
			echo "fstab_version=1" >> $(OUT_OBJ_META)/misc_info.txt; \
		fi;
	$(hide) if [ x"false" = x"$(strip $(USE_ASSERTIONS_IN_UPDATER_SCRIPT))" ]; then \
			echo "use_assertions=false" >> $(OUT_OBJ_META)/misc_info.txt; \
		fi
	$(hide) if [ x"true" = x"$(strip $(MAKE_RECOVERY_PATCH))" ]; then \
			echo "make_recovery_patch=true" >> $(OUT_OBJ_META)/misc_info.txt; \
		fi
	$(hide) if [ x"true" != x"$(strip $(SIGN_OTA))" ]; then \
			echo "not_sign_ota=true" >> $(OUT_OBJ_META)/misc_info.txt; \
		fi
	$(hide) mkdir -p $(OUT_META);
	$(hide) cp $(OUT_OBJ_META)/misc_info.txt $@
	$(hide) echo "<<< generate |target-files|META|misc_config.txt| done";

$(OUT_META)/file_contexts.bin: bootimage ROOT
	$(hide) if [ -f $(OUT_OBJ_BOOT)/RAMDISK/file_contexts.bin ]; then \
			cp -r $(OUT_OBJ_BOOT)/RAMDISK/file_contexts.bin $(OUT_META)/file_contexts.bin; \
		fi
	$(hide) if [ -f $(OUT_ROOT)/file_contexts.bin ]; then \
			cp $(OUT_ROOT)/file_contexts.bin $(OUT_META)/file_contexts.bin; \
		fi

.PHONY: META
TARGET_FILES_META := META
META: $(eval meta_sources := $(filter-out %/filesystem_config.txt %/apkcerts.txt %/linkinfo.txt %/misc_info.txt, \
        $(call get_all_files_in_dir,$(VENDOR_META))))
META: $(OUT_META)/filesystem_config.txt $(OUT_META)/apkcerts.txt $(OUT_META)/misc_info.txt $(OUT_META)/file_contexts.bin
	$(hide) cp $(meta_sources) $(OUT_META);
	$(hide) echo "<< generate |target-files|META| done"
        # convert filesystem_config to data
	$(hide) echo ">> convert filesystem_config to data"
	$(hide) $(CONVERT_FILESYSTEM) $(OUT_META) $(OUT_DATA)
	$(hide) echo "<< convert done"

####################### OTA ############################
.PHONY: OTA
OTA_TARGETS += OTA
OTA $(OUT_OTA): $(strip $(call get_all_files_in_dir,$(VENDOR_OTA))) $(strip $(call get_all_files_in_dir,$(BOARD_OTA)))
	$(hide) echo ">> generate |target-files|OTA| ...";
	$(hide) rm -rf $(OUT_OTA);
	$(hide) mkdir -p $(OUT_OTA);
	$(hide) cp -rf $(VENDOR_OTA)/* $(OUT_OTA);
	$(hide) if [ -d $(BOARD_OTA) ]; then cp -rf $(BOARD_OTA)/* $(OUT_OTA); fi
	$(hide) if [ -d $(PRJ_OTA_OVERLAY) ]; then cp -rf $(PRJ_OTA_OVERLAY)/* $(OUT_OTA); fi
	$(hide) if [ -f $(PRJ_UPDATER_SCRIPT_OVERLAY) ]; then cp $(PRJ_UPDATER_SCRIPT_OVERLAY) $(OUT_OTA); fi
	$(hide) if [ x"$(PRODUCE_BLOCK_BASED_OTA)" = x"false" ]; then \
			cp -rf $(PORT_BUILD)/compatibility/OTA/updater $(OUT_OTA)/bin; \
		fi
	$(hide) echo "<< generate |target-files|OTA| done";

####################### BOOT ############################
.PHONY: BOOT
#OTA_TARGETS += BOOT
BOOT $(OUT_BOOT):
	$(hide) echo ">> generate |target-files|BOOT| ...";
	$(hide) rm -rf $(OUT_BOOT);
	$(hide) mkdir -p $(OUT_BOOT)/RAMDISK;
	$(hide) cp -rf $(PRJ_BOOT_IMG_OUT)/RAMDISK/file_contexts $(OUT_BOOT)/RAMDISK/file_contexts;
	$(hide) echo "<< generate |target-files|BOOT| done";

####################### ROOT ############################
.PHONY: ROOT
OTA_TARGETS += ROOT
ROOT $(OUT_ROOT):
	$(hide) if [ -d $(PRJ_ROOT)/ROOT ]; then \
			echo ">> generate |target-files|ROOT| ..."; \
			rm -rf $(OUT_ROOT); \
			cp -a $(PRJ_ROOT)/ROOT $(OUT_TARGET_DIR); \
		fi
	$(hide) if [ -f $(OUT_ROOT)/file_contexts.bin ]; then \
			echo ">> pack $(OUT_ROOT)/file_contexts.bin ..."; \
			$(SEFCONTEXT_COMPILE_TOOL) -o $(OUT_ROOT)/file_contexts.bin $(OUT_ROOT)/file_contexts; \
			rm -r $(OUT_ROOT)/file_contexts; \
			echo "<< pack $(OUT_ROOT)/file_contexts.bin done"; \
			echo "<< generate |target-files|ROOT| done"; \
		fi

################# update the apk certs #################
.PHONY: updateapkcerts
updateapkcerts: $(OUT_META)/apkcerts.txt
	$(hide) echo "* apkcerts.txt ==> $(OUT_META)/apkcerts.txt"

OTA_TARGETS += $(TARGET_FILES_META)
$(BOARD_META)/apkcerts.txt: $(PREPARE_SOURCE)
	@ echo "Do nothing" > /dev/null

$(OUT_OBJ_META)/apkcerts.txt: USE_VENDOR_CERT_APPS:= $(strip $(patsubst %,%.apk,$(vendor_modify_apps)) $(VENDOR_SIGN_APPS))
$(OUT_OBJ_META)/apkcerts.txt: $(BOARD_META)/apkcerts.txt $(VENDOR_META)/apkcerts.txt
	$(hide) echo ">>> generate |target-files|META|apkcerts.txt| ...";
	$(hide) mkdir -p $(OUT_OBJ_META)
	$(hide) if [ -f $(BOARD_META)/apkcerts.txt ]; then \
			cp $(BOARD_META)/apkcerts.txt $(OUT_OBJ_DIR)/apkcerts.txt; \
		else \
			echo "WARNNING: $(BOARD_META)/apkcerts.txt not found"; \
			$(hide) cat /dev/null > $(OUT_OBJ_DIR)/apkcerts.txt; \
		fi
	$(hide) egrep 'certificate="build/target/product/security|$(CERTS_PATH)|PRESIGNED' $(BOARD_META)/apkcerts.txt \
				| sed 's#build/target/product/security#$(CERTS_PATH)#g'  \
				> $(OUT_OBJ_DIR)/apkcerts.txt;
	$(hide) echo "    USE_VENDOR_CERT_APPS:$(USE_VENDOR_CERT_APPS)"
	$(hide) for apk in $(USE_VENDOR_CERT_APPS); do\
			apkbasename=`basename $$apk`; \
			vendor_cert=`grep "\\"$$apkbasename\\"" $(VENDOR_META)/apkcerts.txt`; \
			echo "    $$apkbasename vendor_cert:$$vendor_cert"; \
			if [ x"$$vendor_cert" != x"" ];then\
				sed -i "/\"$$apkbasename\"/d" $(OUT_OBJ_DIR)/apkcerts.txt;\
				echo $$vendor_cert >> $(OUT_OBJ_DIR)/apkcerts.txt; \
			fi; \
		done;
	$(hide) mkdir -p $(OUT_META)
	$(hide) mv $(OUT_OBJ_DIR)/apkcerts.txt $@;
	$(hide) echo "<<< generate |target-files|META|apkcerts.txt| done"

$(OUT_META)/apkcerts.txt: $(OUT_OBJ_META)/apkcerts.txt
	$(hide) cp $< $@

##################### channel #########################
ifneq ($(strip $(USER)),official)

ifeq ($(strip $(CHANNEL)),)
CHANNEL := 105
endif

TARGET_FILES_SYSTEM += add_channel

.PHONY: add_channel
add_channel: 
	$(hide) echo $(CHANNEL) > $(OUT_SYSTEM)/etc/channel
endif

##################### logo.bin #########################
ifeq ($(strip $(wildcard $(PRJ_LOGO_BIN))),)
LOGO_BIN_PARAM :=
$(OUT_LOGO_BIN):
	$(hide) :	
else
LOGO_BIN_PARAM := -l $(OUT_LOGO_BIN)
$(OUT_LOGO_BIN): $(PRJ_LOGO_BIN)
	$(hide) mkdir -p `dirname $(OUT_LOGO_BIN)`
	$(hide) cp $(PRJ_LOGO_BIN) $(OUT_LOGO_BIN)
endif

##################### prebuilt ##########################
ifeq ($(strip $(wildcard $(PRJ_PREBUILT_OVERLAY))),)
PREBUILT_PARAM :=
else
PREBUILT_PARAM := --prebuilt $(PRJ_PREBUILT_OVERLAY)
endif

################ custom updater-script ##################
ifeq ($(strip $(wildcard $(PRJ_CUSTOM_SCRIPT))),)
CUSTOM_SCRIPT_PARAM :=
else
CUSTOM_SCRIPT_PARAM := --custom_script $(PRJ_CUSTOM_SCRIPT)
endif

################### board_service #######################
ifeq ($(strip $(filter boot boot.img, $(vendor_modify_images))),)
TARGET_FILES_SYSTEM += $(OUT_SYSTEM_BIN)/board_service
endif

$(OUT_SYSTEM_BIN)/board_service: obj_board_service := $(OUT_OBJ_BIN)/board_service
$(OUT_SYSTEM_BIN)/board_service: 
	@ echo ">> target-files:SYSTEM: generate $@ ..."
	$(hide) rm -f $@
	$(hide) mkdir -p $(OUT_SYSTEM_BIN)
	$(hide) mkdir -p `dirname $(obj_board_service)`
	$(hide) if [ -f $(SOURCE_BOOT_RAMDISK_SERVICEEXT) ]; then \
				cp $(SOURCE_BOOT_RAMDISK_SERVICEEXT) $(OUT_SYSTEM_BIN); \
			fi;
	$(hide) echo "#!/system/bin/sh" > $(obj_board_service)
	$(hide) echo "# set su's permission" >> $(obj_board_service)
	$(hide) echo "toolbox mount -o remount,rw /system" >> $(obj_board_service)
	$(hide) echo "toolbox chown root:root /system/xbin/su" >> $(obj_board_service)
	$(hide) echo "toolbox chmod 6755 /system/xbin/su" >> $(obj_board_service)
	$(hide) echo "toolbox mount -o remount,ro /system" >> $(obj_board_service)
	$(hide) echo "# used to start board's daemon, invoid to modify boot.img! " >> $(obj_board_service)
	$(hide) $(foreach service,$(BOARD_SERVICES),\
				echo "$(service) &" >> $(obj_board_service);)
	$(hide) cp $(obj_board_service) $@
	@ echo "<< target-files:SYSTEM: generate $@ ..."

################### target-files #######################
TARGET_FILES_SYSTEM += bootimage recoveryimage
OTA_TARGETS += target-files-system

.PHONY: target-files-system
target-files-system: $(TARGET_FILES_SYSTEM)
	$(hide) $(call custom_post);
	$(hide) echo "<< build |target-files|SYSTEM| done"

target-files: $(OTA_TARGETS)
	$(hide) echo "< build |target-files|PREBUILT,OTA,META,SYSTEM| done"

$(PRJ_OUT_TARGET_ZIP): target-files
	$(hide) echo "> zip $(PRJ_OUT_TARGET_ZIP) from $(OUT_TARGET_DIR) ... "
	$(hide) cd $(OUT_TARGET_DIR) && zip -q -r -y target-files.zip *;
	$(hide) mv $(OUT_TARGET_DIR)/target-files.zip $@;
	$(hide) echo "< zip $(PRJ_OUT_TARGET_ZIP) from $(OUT_TARGET_DIR) done"
	$(hide) echo "* build target-files out ==> $(PRJ_OUT_TARGET_ZIP)"
	$(hide) echo " "


ifneq ($(strip $(SIGN_OTA)),true)
SIGN_OTA_PARAM := --no_sign
endif

ifeq ($(PRJ_FULL_OTA_ZIP),)
PRJ_FULL_OTA_ZIP := $(OUT_DIR)/flyme_$(PRJ_NAME).zip
endif

$(PRJ_FULL_OTA_ZIP): $(OUT_TARGET_ZIP) $(OUT_LOGO_BIN)
	$(hide) echo "> generate ota.zip from target-files.zip (time-costly, be patient) ..."
	$(hide) echo $(PRJ_FULL_OTA_ZIP) > $(PRJ_SAVED_OTA_NAME)
	$(hide) echo $(OUT_TARGET_ZIP) > $(PRJ_SAVED_TARGET_NAME)
ifeq ($(strip $(PRODUCE_IS_AB_UPDATE)),true)
	$(hide) $(ADD_IMG_TO_TARGET_FILES) -a $(OUT_TARGET_ZIP)
endif
	$(hide) $(OTA_FROM_TARGET_FILES) -v \
			$(if $(filter false,$(PRODUCE_BLOCK_BASED_OTA)),,--block) \
			--binary $(PRJ_UPDATE_BINARY_OVERLAY) \
			--no_prereq \
			-e $(PRJ_UPDATER_SCRIPT_PART) \
			-k $(OTA_CERT) \
			$(OUT_TARGET_ZIP) $(PRJ_FULL_OTA_ZIP) \
			|| exit 51
	$(hide) echo "< generate ota.zip from target-files.zip done"
	$(hide) echo "* build ota.zip out ==> $(PRJ_FULL_OTA_ZIP)"
	$(hide) echo " "

ifeq ($(PRJ_TARGET_ZIP),)
PRJ_TARGET_ZIP := $(OUT_TARGET_ZIP)
endif

ota-files-zip: $(PRJ_FULL_OTA_ZIP) mkuserimg
ota-files-zip: DATE := $(shell date +%Y%m%d%H%M)
ota-files-zip:
ifneq ($(PRJ_TARGET_ZIP),$(OUT_TARGET_ZIP))
	$(hide) mv $(OUT_TARGET_ZIP) $(PRJ_TARGET_ZIP)
endif
	@ echo "* OUT ==> $(PRJ_TARGET_ZIP)";
	@ echo "$(PRJ_TARGET_ZIP)" > $(PRJ_SAVED_TARGET_NAME);
	@ echo "* OUT ==> $(PRJ_FULL_OTA_ZIP)";
	@ echo "$(PRJ_FULL_OTA_ZIP)" > $(PRJ_SAVED_OTA_NAME);

.PHONY: mkuserimg

ifeq ($(strip $(PRODUCE_IMAGES_FOR_FASTBOOT)),true)
mkuserimg: $(OUT_TARGET_ZIP)
	$(hide) echo "> mkuserimg from $(OUT_TARGET_ZIP)"
	$(hide) $(IMG_FROM_TARGET_FILES) $(OUT_TARGET_ZIP) \
			$(OUT_DIR)/target-files.signed.zip || exit 52
	$(hide) unzip -o $(OUT_DIR)/target-files.signed.zip -d $(OUT_DIR);
	$(hide) rm -f $(OUT_DIR)/target-files.signed.zip;
	$(hide) echo "< mkuserimg from $(OUT_TARGET_ZIP) done"
	$(hide) echo " "
else
mkuserimg:
	$(hide) echo "< nothing to do for mkuserimg"
endif

##################  server-ota #########################
ifneq ($(wildcard $(PORT_BUILD)/custom/server_ota.mk),)
include $(PORT_BUILD)/custom/server_ota.mk
endif

############### dex target-files #######################
include $(PORT_BUILD)/dex_opt.mk

ifneq ($(wildcard $(PORT_BUILD)/custom/sign_ota.mk),)
include $(PORT_BUILD)/custom/sign_ota.mk
endif

############## add prepare_source ######################
$(BOARD_SYSTEM)/%: $(PREPARE_SOURCE)
	@echo "< prepare $@ done" > /dev/null

################### clean ##############################
.PHONY: clean
clean: $(CLEAN_TARGETS) 
	$(hide) echo "< clean done"

.PHONY: clean-all
clean-all: clean clean-board-zip clean-autopatch

################### autopatch ##############################
include $(PORT_BUILD)/autopatch.mk

################### autofix ##############################
include $(PORT_BUILD)/autofix.mk

################### otadiff ##############################
include $(PORT_BUILD)/otadiff.mk

#$(info # ------------------------------------------------------------------)
