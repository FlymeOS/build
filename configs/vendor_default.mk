# the vendor files which need copy to target

# you can use vendor_remove_dirs 
# to config which dirs in system need to be remove 
# the app directory must be remove
vendor_remove_dirs  += \
	app \
	priv-app \
	media/audio/

vendor_remove_files += \
	media/bootanimation.zip \
	media/bootaudio.mp3 \
	media/shutaudio.mp3 \
	media/shutanimation.zip \
	media/shutdownanimation.zip \
    recovery-from-boot.p

VENDOR_REMOVE_DIRS  := $(sort $(strip $(vendor_remove_dirs)))
VENDOR_REMOVE_FILES := $(sort $(strip $(vendor_remove_files)))
