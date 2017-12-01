
DECODE_TARGET_BOARD :=
DECODE_TARGET_VENDOR :=
DECODE_TARGET_MERGED :=
NEED_COMPELETE_MODULE :=
$(foreach pair,$(NEED_COMPELETE_MODULE_PAIR),\
     $(eval src := $(call word-colon,1,$(pair)))\
     $(eval dst := $(call word-colon,2,$(pair)))\
     $(eval board_src := $(patsubst %,$(BOARD_SYSTEM)/%,$(strip $(src))))\
     $(eval board_target := $(patsubst %,$(AUTOCOM_BOARD)/%,$(strip $(dst))))\
     $(eval $(call decode_board,$(board_src),$(board_target)))\
     $(eval $(board_src): $(PREPARE_SOURCE))\
     $(eval DECODE_TARGET_BOARD += $(board_target)/apktool.yml)\
     $(eval vendor_src := $(patsubst %,$(VENDOR_SYSTEM)/%,$(strip $(src))))\
     $(eval vendor_target := $(patsubst %,$(AUTOCOM_VENDOR)/%,$(strip $(dst))))\
     $(if $(wildcard $(vendor_src)),\
          $(eval NEED_COMPELETE_MODULE += $(dst))\
          $(eval $(call decode_vendor,$(vendor_src),$(vendor_target)))\
          $(eval DECODE_TARGET_VENDOR += $(vendor_target)/apktool.yml)))

$(foreach pair,$(VENDOR_COM_MODULE_PAIR),\
     $(eval src := $(call word-colon,1,$(pair)))\
     $(eval dst := $(call word-colon,2,$(pair)))\
     $(eval vendor_src := $(patsubst %,$(VENDOR_SYSTEM)/%,$(strip $(src))))\
     $(eval vendor_target := $(patsubst %,$(AUTOCOM_MERGED)/%,$(strip $(dst))))\
     $(eval $(call decode_vendor,$(vendor_src),$(vendor_target)))\
     $(eval DECODE_TARGET_MERGED += $(vendor_target)/apktool.yml))

.PHONY: autocom_prepare_board autocom_prepare_vendor autocom_prepare_merged

.IGNORE: $(DECODE_TARGET_BOARD) $(DECODE_TARGET_VENDOR)

autocom_prepare_board $(AUTOCOM_PREPARE_BOARD): $(DECODE_TARGET_BOARD)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_BOARD)`
	$(hide) touch $(AUTOCOM_PREPARE_BOARD)

autocom_prepare_vendor $(AUTOCOM_PREPARE_VENDOR): $(DECODE_TARGET_VENDOR)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_VENDOR)`
	$(hide) touch $(AUTOCOM_PREPARE_VENDOR)

autocom_prepare_merged $(AUTOCOM_PREPARE_MERGED): $(AUTOCOM_PREPARE_VENDOR) $(AUTOCOM_PREPARE_BOARD) $(DECODE_TARGET_MERGED)
	$(hide) mkdir -p `dirname $(AUTOCOM_PREPARE_MERGED)`
	$(hide) $(foreach vModifyJar,$(vendor_modify_jars),cp -rf $(PRJ_ROOT)/$(vModifyJar).jar.out $(AUTOCOM_MERGED);)
	$(hide) ls $(AUTOCOM_BOARD)/* 2>&1 > /dev/null; if [ "$$?" = "0" ]; then cp -rf $(AUTOCOM_BOARD)/* $(AUTOCOM_MERGED); fi
	$(hide) touch $(AUTOCOM_PREPARE_MERGED)

autofix $(AUTOCOM_PRECONDITION): $(AUTOCOM_PREPARE_BOARD) $(AUTOCOM_PREPARE_VENDOR) $(AUTOCOM_PREPARE_MERGED)
	@echo ">>> autocomplete missed methods ..."
	$(hide) rm -rf $(AUTOCOM_PRECONDITION)
	$(hide) $(if $(NEED_COMPELETE_MODULE),$(SCHECK) --autocomplete \
				$(AUTOCOM_VENDOR) \
				autopatch/aosp \
				$(AUTOCOM_BOARD) \
				$(AUTOCOM_MERGED) \
				$(PRJ_ROOT) \
				$(NEED_COMPELETE_MODULE),)
	$(hide) touch $(AUTOCOM_PRECONDITION)

# auto fix reject
AUTOFIX_TARGET_LIST := $(patsubst %,%.jar.out,$(vendor_modify_jars))
AUTOFIX_DECODE_JARS := $(patsubst %,$(VENDOR_FRAMEWORK)/%,core.jar)
AUTOFIX_OBJ_TARGET_LIST := $(patsubst %,$(AUTOFIX_TARGET)/%,$(AUTOFIX_TARGET_LIST))

.PHONY: autofix_check
autofix_check:
	$(hide) if [ ! -d $(PRJ_ROOT)/autopatch/reject ]; then \
				echo ">>>> Error: reject doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;
	$(hide) if [ ! -d autopatch/bosp ]; then \
				echo ">>>> Error: autopatch/bosp doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;
	$(hide) if [ ! -d autopatch/aosp ]; then \
				echo ">>>> Error: autopatch/aosp doesn't exist! You need run 'make patchall' first!"; \
				exit 1; \
			fi;

.PHONY: autofix_prepare_target
.PHONY: autofix_prepare_target_internal
autofix_prepare_target_internal $(AUTOFIX_PREPARE_TARGET): $(IF_VENDOR_RES)
	$(hide) rm -rf $(AUTOFIX_TARGET)
	$(hide) mkdir -p $(AUTOFIX_TARGET)
	$(hide) $(foreach jar,$(AUTOFIX_TARGET_LIST), \
				if [ -d $(jar) ]; then \
					$(call dir_copy,$(jar),$(AUTOFIX_TARGET)/$(jar)) \
					$(eval jarBaseName := $(call getBaseName,$(call getBaseName,$(jar)))) \
					$(foreach package,$(BOARD_PREBUILT_PACKAGE_$(jarBaseName)),\
						$(eval srcDir := autopatch/bosp/$(jar)/smali/$(package)) \
						$(eval destDir := $(AUTOFIX_TARGET)/$(jar)/smali/$(package)) \
						$(call safe_dir_copy,$(srcDir),$(destDir))) \
				else \
					echo ">>> Warning: $(jar) doesn't exsit! Are you run 'makeconfig' and 'make newproject' before?"; \
					echo "             this may cause AttributeError when run reject.py"; \
				fi;)
	$(hide) $(foreach jar,$(AUTOFIX_DECODE_JARS),$(call decode,$(jar),$(AUTOFIX_TARGET)/$(notdir $(jar)).out,$(APKTOOL_VENDOR_TAG)))
	$(hide) touch $(AUTOFIX_PREPARE_TARGET)

.IGNORE: $(AUTOCOM_PRECONDITION)

autofix_prepare_target: autofix_check $(AUTOFIX_PREPARE_TARGET) $(AUTOCOM_PRECONDITION)

define copy_obj_target_to_device
	$(hide) $(foreach jar,$(AUTOFIX_TARGET_LIST), \
				$(eval jarBaseName := $(call getBaseName,$(call getBaseName,$(jar)))) \
				$(foreach package,$(BOARD_PREBUILT_PACKAGE_$(jarBaseName)),\
					rm -rf $(AUTOFIX_TARGET)/$(jar)/smali/$(package);))
	$(hide) $(foreach jar,$(AUTOFIX_OBJ_TARGET_LIST),if [ -d $(jar) ]; then cp -rf $(jar) $(PRJ_ROOT); fi;)
endef

$(AUTOFIX_PYTHON_JOB): autofix_prepare_target
	$(hide) rm -rf $(AUTOFIX_OUT)
	$(hide) rm -rf autopatch/.reject_bak
	$(hide) cp -rf autopatch/reject autopatch/.reject_bak
	$(hide) $(AUTOFIX_TOOL)
	$(hide) rm -rf autopatch/reject
	$(hide) mv autopatch/.reject_bak autopatch/reject
	$(hide) touch $(AUTOFIX_PYTHON_JOB)

.PHONY: fixreject
fixreject $(AUTOFIX_JOB): $(AUTOFIX_PYTHON_JOB)
	$(call copy_obj_target_to_device)

$(SMALI_TO_BOSP_PYTHON_JOB): autofix_prepare_target_internal
	$(hide) $(SCHECK) --smalitobosp `cat $(SMALI_FILE)`

.PHONY: smalitobosp
smalitobosp: $(SMALI_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)

.PHONY: methodtobosp
$(METHOD_TO_BOSP_PYTHON_JOB): autofix_prepare_target_internal
	$(hide) $(SCHECK) --methodtobosp $(SMALI_FILE) `if [ -f $(METHOD) ]; then cat $(METHOD); else echo $(METHOD); fi;`
	$(hide) touch $(METHOD_TO_BOSP_PYTHON_JOB)

methodtobosp:
methodtobosp: $(METHOD_TO_BOSP_PYTHON_JOB)
	$(call copy_obj_target_to_device)
