# prebuilt_64.mk

BOARD_PREBUILT += \
    lib64/libdlna_jni.so \
    lib64/libDominantColors.so \
    lib64/libeffects_filters.so \
    lib64/libeffects_mosaic.so \
    lib64/libeglbitmap.so \
    lib64/libexif_gallery.so \
    lib64/libfilterUtils.so \
    lib64/libimage_codec.so \
    lib64/libimage_dehazing.so \
    lib64/libimageproc.so \
    lib64/libjni_glrenderer.so \
    lib64/libjni_pacprocessor.so \
    lib64/libjni_systemui.so \
    lib64/libjni_systemuitools.so \
    lib64/libmcode_image.so \
    lib64/libnative_blur.so \
    lib64/libnative_glrenderer.so \
    lib64/libnicipher.so \
    lib64/libphoto_process.so \
    lib64/librender_engine.so \
    lib64/libskia_hw_interface.so \
    lib64/libtaglib.so \
    lib64/libvlife_media.so \
    lib64/libvlife_openglutil.so \
    lib64/libvlife_render.so

ifeq ($(strip $(PRODUCE_INTERNATIONAL_ROM)),true)
BOARD_PREBUILT += \

else
BOARD_PREBUILT += \
    lib64/libHAOMA.so

endif
