# build.prop.mk
# the default board prop

sub_space := \#

################# buildprop ############################

$(foreach property,$(BOARD_PROPERTY_FOLLOW_BASE),\
    $(eval propValue := $(shell $(call getprop,$(property),$(BOARD_SYSTEM)/build.prop))) \
    $(if $(propValue),\
        $(eval BOARD_PROPERTY_OVERRIDES := $(filter-out $(property)=%,$(BOARD_PROPERTY_OVERRIDES))) \
        $(eval BOARD_PROPERTY_OVERRIDES += $(property)=$(propValue)) \
    ) \
)

BOARD_PROPERTY_OVERRIDES := \
     $(call collapse-pairs, $(BOARD_PROPERTY_OVERRIDES))

PROPERTY_REMOVE := $(remove_property)

PROPERTY_OVERRIDES := \
     $(strip $(override_property) $(BOARD_PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst $(space),$(sub_space),$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst $(sub_space)=,=,$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(subst =$(sub_space),=,$(PROPERTY_OVERRIDES))

PROPERTY_OVERRIDES := \
     $(shell echo '$(PROPERTY_OVERRIDES)' | sed -e "s/$(sub_space)\([^$(sub_space)]*\=\)/ \1/g")

PROPERTY_OVERRIDES := \
     $(call uniq-pairs-by-first-component,$(PROPERTY_OVERRIDES),=)

$(OUT_OBJ_SYSTEM)/board.build.prop: $(BOARD_SYSTEM)/build.prop $(PRJ_MAKEFILE)
	$(hide) echo ">> overries properties ..."
	$(hide) mkdir -p $(OUT_OBJ_SYSTEM)
	$(hide) $(foreach line,$(PROPERTY_OVERRIDES), \
			echo "$(line)" | sed 's/$(sub_space)/ /g' >> $@;)
	$(hide) $(foreach line,$(PROPERTY_REMOVE), \
			echo "$(line)=delete" >> $@;)
	$(hide) echo "<< overries properties done"

.PHONY: build_prop
TARGET_FILES_SYSTEM += $(OUT_SYSTEM)/build.prop

#$(info # VERSION_NUMBER: $(VERSION_NUMBER))

build_prop $(OUT_SYSTEM)/build.prop: $(OUT_OBJ_SYSTEM)/board.build.prop
build_prop $(OUT_SYSTEM)/build.prop: $(VENDOR_BUILD_PROP)
	$(hide) echo ">> make build.prop, with version number: $(VERSION_NUMBER)"
	$(hide) mkdir -p $(OUT_SYSTEM)
	$(hide)	$(MAKE_BUILD_PROP) \
			-b $(OUT_OBJ_SYSTEM)/board.build.prop \
			-r $(VENDOR_BUILD_PROP) \
			-o $(OUT_SYSTEM)/build.prop
	$(hide) if [ -x $(PRJ_CUSTOM_BUILDPROP) ];then \
				$(PRJ_CUSTOM_BUILDPROP) $(OUT_SYSTEM)/build.prop; \
			fi;
	$(hide) echo "<< make build.prop, with version number done.";
	$(hide) echo "* build.prop out ==> $(OUT_SYSTEM)/build.prop"
	$(hide) echo " "

.PHONY: clean-build_prop
clean-build_prop:
	$(hide) rm -rf $(OUT_SYSTEM)/build.prop
	$(hide) rm -rf $(OUT_OBJ_SYSTEM)/board.build.prop
