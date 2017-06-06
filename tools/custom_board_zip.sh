#!/bin/bash

BOARD_ZIP_DIR=$1
DENSITY=$2

VENDOR_SYSTEM=$3
BOARD_RELEASE=$4

THEME_FULL_RES=$BOARD_ZIP_DIR/theme_full_res

function custom_theme()
{
	if [ -d $THEME_FULL_RES ]; then
		for theme in $(ls $THEME_FULL_RES | awk -F- '{print $1}' | sort | uniq); do
			package=$theme
			if [ -d $THEME_FULL_RES/$theme-$DENSITY ]; then
				package=$theme-$DENSITY
			fi
			if [ -d $THEME_FULL_RES/$package ]; then
				rm -rf $BOARD_ZIP_DIR/system/etc/$theme
				rm -rf $BOARD_ZIP_DIR/system/etc/$theme.btp
				mv $THEME_FULL_RES/$package $BOARD_ZIP_DIR/system/etc/$theme

				cd $BOARD_ZIP_DIR/system/etc/$theme 2>&1 > /dev/null
				zip -q ../$theme.btp description.xml
				cd - 2>&1 > /dev/null
			fi
		done
		rm -rf $THEME_FULL_RES
	fi
}

function custom_arm64
{
	cpuAbi=$(grep "ro.product.cpu.abi=" $VENDOR_SYSTEM/build.prop | awk -F\= '{print $2}' | head -1)
	if [ "x$VENDOR_SYSTEM" != "x" ] && [ "x$cpuAbi" = "xarm64-v8a" ]; then
		if [ "x$BOARD_RELEASE" != "x" ] ; then
			ARM_64="$(dirname $BOARD_RELEASE)/arm64"
			if [ -d "$ARM_64" ]; then
				for f in $(ls $ARM_64); do
					if [ "$f" == "SYSTEM" ]; then
						cp -rf $ARM_64/$f/* $BOARD_ZIP_DIR/system
					else
						cp -rf $ARM_64/$f $BOARD_ZIP_DIR
					fi
				done
			fi
		fi
	fi
}

function custom_flymeRes()
{
	if [ -f $BOARD_ZIP_DIR/system/framework/flyme-res/flyme-res.jar ]; then
		mv $BOARD_ZIP_DIR/system/framework/flyme-res/flyme-res.jar $BOARD_ZIP_DIR/system/framework/flyme-res/flyme-res.apk
	fi
}

custom_theme
custom_arm64
custom_flymeRes
