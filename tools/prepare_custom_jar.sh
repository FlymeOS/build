#!/bin/bash

jarBaseName=$1
tempSmaliDir=$2

WORK_DIR=$PWD
BOARD_DIR=$WORK_DIR/board
OUT_OBJ_DIR=$WORK_DIR/out/obj
MERGE_UPDATE_TXT=$OUT_OBJ_DIR/system/res/merge_update.txt

MODIFY_ID_TOOL=$PORT_ROOT/build/tools/modifyID.py

## TODO delete
if [ "$jarBaseName" = "android.policy" ];then
	BOARD_FRAMEWORK_YI=$BOARD_DIR/system/framework/framework-yi.jar
	
	if [ -f $BOARD_FRAMEWORK_YI ]; then
		tempYi=`mktemp -u $OUT_OBJ_DIR/framework-yi.XXXX`
		rm -rf $tempYi
		mkdir -p $tempYi
		
		apktool d -f $BOARD_FRAMEWORK_YI $tempYi
		$MODIFY_ID_TOOL $MERGE_UPDATE_TXT $tempYi
		
		#echo ">>> copy framework-yi.jar's package(`cd $tempYi/smali/ >/dev/null; find -type d; cd - > /dev/null`) to android.policy.jar"
		cp -rf $tempYi/smali $tempSmaliDir
	fi
fi
