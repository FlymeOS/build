# define BOARD_PREBUILT_BLACK_LIST, which should not copy to vendor

BLACK_LIST_DIRS += \
	lib/egl/% \
	lib/hw/% \
	lib/modules/% \
	etc/firmware/% \
	etc/bluetooth/% \
	etc/localTheme01/% \
	framework/% \
	vendor/% \
	lib/soundfx/% \
	usr/keylayout/% \
	usr/keychars/% \
	xbin/% \
	bin/% \

BLACK_LIST += \
	lib/libc_malloc_debug_leak.so \
	lib/libc_malloc_debug_qemu.so \
	lib/libttscompat.so \
	lib/libttspico.so \
	lib/libOMX% \
	etc/portable_camera.xml \
	etc/localTheme01.btp \
	etc/security/otacerts.zip \
	app/Bluetooth.apk \
	app/FMRadio.apk \
	app/MtkBt.apk \
	app/NfcNci.apk \
	app/Nfc.apk

BLACK_LIST += \
	$(notdir $(PREPARE_SOURCE))

