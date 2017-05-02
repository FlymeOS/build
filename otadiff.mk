# otadiff.mk

.PHONY: otadiff

ifneq ($(wildcard $(PRE)),)
PRE_TARGET_ZIP := $(PRE)
endif

ifneq ($(wildcard $(PRE_TARGET_ZIP)),)
otadiff: local_target := $(shell if [ -f $(PRJ_SAVED_TARGET_NAME) ];then cat $(PRJ_SAVED_TARGET_NAME); fi)
otadiff:
	@echo ">>> build Incremental OTA Package from $(PRE_TARGET_ZIP) to $(local_target)"
	$(hide) otadiff $(PRE_TARGET_ZIP) $(local_target)
else
otadiff:
	@echo "USAGE:"
	@echo "   Preparing target_files.zip of previous version in current directory,   "
	@echo "   make otadiff => build an Incremental OTA Package.                      "
	@echo "   make otadiff PRE=xx/xx/target_files_xx.zip => specify previous package."
	@echo "   make otadiff PRE=xx/xx/ota_xx.zip => specify previous ota package.     "
	$(hide) exit 1
endif
	 