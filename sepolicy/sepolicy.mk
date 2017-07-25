# sepolicy.mk

SEPOLICY_DIR        := $(PORT_BUILD)/sepolicy

KEYS_CONF           := $(SEPOLICY_DIR)/keys.conf

mac_perms_keys.tmp := $(OUT_OBJ_DIR)/keys.tmp
$(mac_perms_keys.tmp) : $(KEYS_CONF)
	@mkdir -p $(dir $@)
	$(hide) m4 -s $^ > $@

.PHONY: mac_permissions
TARGET_FILES_SYSTEM += mac_permissions


mac_permissions: $(mac_perms_keys.tmp) $(OUT_MAC_PERMISSIONS_XML)
	$(hide) echo ">>> generating $@ ..."
	$(hide) DEFAULT_SYSTEM_DEV_CERTIFICATE=`echo $(PORT_ROOT)/$(CERTS_PATH)` \
		$(SEPOLICY_DIR)/insertkeys.py $< $(SEPOLICY_DIR)/mac_permissions.xml -o $(OUT_DIR)/tmp.xml
	$(hide) $(SEPOLICY_DIR)/addkeys.py $(OUT_DIR)/tmp.xml $(OUT_MAC_PERMISSIONS_XML)
	$(hide) DEFAULT_SYSTEM_DEV_CERTIFICATE=`echo $(PORT_ROOT)/$(CERTS_PATH)` \
		$(SEPOLICY_DIR)/insertkeys.py $< $(OUT_MAC_PERMISSIONS_XML) -o tmp.xml
	$(hide) mv tmp.xml $(OUT_MAC_PERMISSIONS_XML)
	$(hide) echo "<<< generating mac_permissions.xml done"
	$(hide) echo "* mac_permissions.xml out ==> $(OUT_MAC_PERMISSIONS_XML)"
	$(hide) echo " "

