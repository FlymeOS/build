
empty :=
space := $(empty) $(empty)

left_bracket := (
right_bracket := )

# get the words split by :
define word-colon
$(word $(1),$(subst :,$(space),$(2)))
endef

define collapse-pairs
$(eval _cpSEP := $(strip $(if $(2),$(2),=)))\
$(subst $(space)$(_cpSEP)$(space),$(_cpSEP),$(strip \
    $(subst $(_cpSEP), $(_cpSEP) ,$(1))))
endef

define uniq-pairs-by-first-component
$(eval _upbfc_fc_set :=)\
$(strip $(foreach w,$(1), $(eval _first := $(word 1,$(subst $(2),$(space),$(w))))\
    $(if $(filter $(_upbfc_fc_set),$(_first)),,$(w)\
        $(eval _upbfc_fc_set += $(_first)))))\
$(eval _upbfc_fc_set :=)\
$(eval _first:=)
endef

# used to mkdir
define mkdir_p
$(1):
	$(hide) echo "mkdir -p $(1)"
	$(hide) mkdir -p $(1);
endef

# get the basename of apk or jar
define getBaseName
$(basename $(notdir $(1)))
endef

# get all files in the directory, only for makefile
define get_all_files_in_dir
$(strip $(filter-out $(1),$(shell if [ -d $(1) ]; then find $(1) -type f -o -type l; fi)))
endef

# get all smali files in the directory, only for find xx.jar.out, process "$" symbol
define get_all_smali_files_in_dir
$(strip $(filter-out $(1),$(shell if [ -d $(1) ]; then find $(1) -type f | sed 's/\$$/\$$$$/g' | tee /tmp/find; fi)))
endef

define change_bracket
$(subst $(right_bracket),\$(right_bracket),$(subst $(left_bracket),\$(left_bracket),$(1)))
endef

define safe_dir_copy
	if [ -d $(1) ]; then mkdir -p $(2) && cp -rf $(1)/* $(2); fi;
endef

define dir_copy
	mkdir -p $(2) && cp -r $(1)/* $(2);
endef

define safe_file_copy
	if [ -f $(1) ]; then mkdir -p `dirname $(2)` && cp -f $(1) $(2); fi;
endef

define file_copy
	mkdir -p `dirname $(2)` && cp $(1) $(2);
endef

# clean the app or jar
# you can add some target to remove by set "remove_targets"
# eg:
# 	clean-framework-res: remove_targets += xxxx
define clean-app
.PHONY: clean-$(call getBaseName, $(2))
clean-$(call getBaseName, $(2)): remove_targets += $(filter-out $(VENDOR_DIR)/%,$(filter-out $(BOARD_DIR)/%,$(1) $(2)))
clean-$(call getBaseName, $(2)): remove_targets += $(OUT_OBJ_APP)/$(call getBaseName, $(2))\.*
clean-$(call getBaseName, $(2)):
	rm -rf $$(remove_targets)
	$(hide) echo ">>> clean $$@ done!"
endef
define clean-jar
.PHONY: clean-$(call getBaseName, $(2))
clean-$(call getBaseName, $(2)): remove_targets += $(filter-out $(VENDOR_DIR)/%,$(filter-out $(BOARD_DIR)/%,$(1) $(2)))
clean-$(call getBaseName, $(2)): remove_targets += $(OUT_OBJ_FRAMEWORK)/$(call getBaseName, $(2))\.*
clean-$(call getBaseName, $(2)):
	rm -rf $$(remove_targets)
	$(hide) echo ">>> clean $$@ done!"
endef

# define the target xxx.phone
# it will push the apk or jar to the phone
define push_phone
$(call getBaseName, $(2)).phone: baseDir := $(patsubst $(OUT_SYSTEM)/%,%,$(2))
$(call getBaseName, $(2)).phone: baseName := $(notdir $(2))
$(call getBaseName, $(2)).phone: $(2)
	$(hide) echo ">>> push $(2) to Phone"
	$(hide) $(PUSH) -p $(DEEFAULT_PERMISSION) $$< /system/$$(baseDir)
endef

define get_base_version
echo $(1) | grep "_[DRS]_[0-9]*.[0-9]*" -o | awk -F_ '{print $$NF}'
endef

define get_new_version
$(eval base_version := $(shell $(call get_base_version,$(2)))) \
if [ "x$(base_version)" != "x" ];then \
    echo "$(1)" | sed "s/\(_[DRS]_\)[0-9]*\.[0-9]*/\1$(base_version)/"; \
else \
    echo "$(1)";\
fi
endef

define getprop
if [ -f $(2) ]; then \
    grep -v "^[ \t]*#" $(2) | awk -F= '/$(1)/{print $$2}' | tail -1; \
fi
endef

define getprop_filter_version
if [ -f $(2) ]; then \
    grep -v "^[ \t]*#" $(2) | awk -F= '/$(1)/{print $$2}' | tail -1 | grep -o "[0-9\.IR]*"; \
fi
endef

define getprop_escape_space
if [ -f $(2) ]; then \
    grep -v "^[ \t]*#" $(2) | awk -F= '/$(1)/{print $$2}' | tail -1 | sed -e 's/[  _]/-/g'; \
fi
endef


define getMinSdkVersionFromApktoolYml
if [ -f $(1) ]; then awk '/minSdkVersion:/{print $$NF}' $(1) | grep '[0-9]*' -o; fi
endef

define getMinSdkVersionFromApktoolYmlFD
if [ -f $(1) ]; then awk '/minSdkVersion:/{print $$$$NF}' $(1) | grep '[0-9]*' -o; fi
endef

define getTargetSdkVersionFromApktoolYml
if [ -f $(1) ]; then awk '/targetSdkVersion:/{print $$NF}' $(1) | grep '[0-9]*' -o; fi
endef

define getTargetSdkVersionFromApktoolYmlFD
if [ -f $(1) ]; then awk '/targetSdkVersion:/{print $$$$NF}' $(1) | grep '[0-9]*' -o; fi
endef


define formatOverlay
if [ -d $(1) ]; then find $(1) -name "*.xml" | xargs sed -i 's/\( name *= *"\)android:/\1/g'; fi
endef

define __posOfFile__
$(patsubst $(2)/%,%,\
	$(shell if [ -d "$(2)" ]; then \
				if [ -f "$(2)/$(1)" ]; then \
					echo "$(2)/$(1)"; \
				else \
					find "$(2)" -name $(notdir $(1)) | head -1; \
				fi; \
			fi;))
endef

define posOfFile
$(eval realPos := $(call __posOfFile__,$(1),$(2))) \
$(if $(realPos),$(realPos),$(1))
endef

define isExist
$(eval realPos := $(call __posOfFile__,$(1),$(2))) \
$(if $(realPos),$(realPos),)
endef

define posOfApp
$(strip $(eval appName := $(patsubst %,%.apk,$(patsubst %.apk,%,$(1)))) \
$(call posOfFile,$(appName),$(2)) \
$(eval appName :=))
endef

define posOfJar
$(strip $(eval jarName := $(patsubst %,%.jar,$(patsubst %.jar,%,$(1)))) \
$(call posOfFile,$(jarName),$(2)) \
$(eval jarName :=))
endef

define resetPosition
$(eval PRE_SET := $($(1))) \
$(eval $(1) := )\
$(foreach pos,$(PRE_SET),$(eval $(1) += $(call posOfFile,$(pos),$(2)))) \
$(eval PRE_SET := )
endef

define resetPositionApp
$(eval PRE_SET := $($(1))) \
$(eval $(1) := )\
$(foreach pos,$(PRE_SET),$(eval $(1) += $(call posOfApp,$(pos),$(2)))) \
$(eval PRE_SET := )
endef

define resetPositionJar
$(eval PRE_SET := $($(1))) \
$(eval $(1) := )\
$(foreach pos,$(PRE_SET),$(eval $(1) += $(call posOfJar,$(pos),$(2)))) \
$(eval PRE_SET := )
endef

define posOfDir
$(eval _FIND_DIRS := $(shell if [ -d $(2) ]; then find $(2) -type d -name $(1); fi;)) \
$(foreach d,$(_FIND_DIRS),$(call get_all_files_in_dir,$(d)))
endef

define getAllFilesInApp
$(eval PRE_SET := $($(1))) \
$(eval $(1) := )\
$(foreach pos,$(PRE_SET),$(eval $(1) += $(call posOfDir,$(pos),$(2)))) \
$(eval PRE_SET := )
endef
