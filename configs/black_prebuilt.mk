# define BOARD_PREBUILT_BLACK_LIST, which should not copy to vendor

BLACK_LIST_DIRS += \
	etc/bluetooth/% \
	etc/firmware/% \
	lib/drm/% \
	lib/egl/% \
	lib/hw/% \
	lib/soundfx/% \
	lib64/drm/% \
	lib64/hw/% \
	lib64/soundfx/% \
	usr/% \
	vendor/% \
	xbin/%

BLACK_LIST += \
	app/Bluetooth/Bluetooth.apk

BLACK_LIST += \
	$(notdir $(PREPARE_SOURCE))

