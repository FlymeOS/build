#!/bin/bash

TOOL_NAME="flash_ota_to_device.sh"
TMP_COMMAND=".tmp_command"
COMMAND_DIR=/cache/recovery
COMMAND_NAME=command
TMP_SHELL=tmp_shell.sh
PACKAGE_DIR=/data/local/tmp
PACKAGE_NAME=ota.zip

######## Error Exit Num ##########
ERR_USB_NOT_CONNECTED=151
ERR_DEVICE_NOT_ROOTED=152

# wait for the device to be online or timeout
function waitForDeviceOnline {
	echo ">>> Wait for the device to be online..."

	local timeout=30
	while [ $timeout -gt 0 ]
	do
		if adb shell ls > /dev/null 2>&1; then
			echo ">>> device is online"
			break
		fi
		echo ">>> device is not online, wait .."
		sleep 3
		timeout=$[$timeout - 3]
	done
	if [ $timeout -eq 0 ];then
		echo ">>> Please ensure adb can find your device and then rerun this script."
		exit $ERR_USB_NOT_CONNECTED
	fi
}

# check system root state
function checkRootState {
	echo ">>> Check root state of phone ..."
	waitForDeviceOnline
	SECURE_PROP=$(adb shell cat /default.prop | grep -o "ro.secure=\w")
	DEBUG_PROP=$(adb shell cat /default.prop | grep -o "ro.debuggable=\w")
	if [ "$SECURE_PROP" = "ro.secure=0" -o "$DEBUG_PROP" = "ro.debuggable=1" ];then
		ROOT_STATE="kernel_root"
		echo ">>> Root State: Kernel Root"
		adb root
		waitForDeviceOnline
	else
		echo "exit" > exit_command
		waitForDeviceOnline
		adb push exit_command /data/local/tmp
		rm -f exit_command
		if echo "su < /data/local/tmp/exit_command; exit" | adb shell | grep "not found" > /dev/null 2>&1;then
			echo ">>> ERROR: Not a root phone, please root this device firstly"
			exit $ERR_DEVICE_NOT_ROOTED;
		fi
		ROOT_STATE="system_root"
		echo ">>> Root State: System Root"
	fi
}

function usage() {
	echo "USAGE: $TOOL_NAME ota-path"
	echo "       $TOOL_NAME out/ota.zip"
	exit 1
}

function pushPackage() {
	echo ">>> Push $OTA_PATH to $PACKAGE_DIR/$PACKAGE_NAME ..."
	adb shell mkdir -p $PACKAGE_DIR
	adb push $OTA_PATH $PACKAGE_DIR/$PACKAGE_NAME
	if [ $? != 0 ];then
		echo ">>> Push package Failed!"
		exit 1
	fi
	echo ">>> Push package Success!"
}

function createCommand() {
	echo "--update_package=$PACKAGE_DIR/$PACKAGE_NAME" > $TMP_COMMAND
	echo "--wipe_data" >> $TMP_COMMAND
	if [ "$ROOT_STATE" = "kernel_root" ];then
		adb shell mkdir -p $COMMAND_DIR
		adb push $TMP_COMMAND $COMMAND_DIR/$COMMAND_NAME
		if [ "$?" = "0" ];then
			rm -f $TMP_COMMAND
			echo "$COMMAND_DIR/$COMMAND_NAME:"
			adb shell cat $COMMAND_DIR/$COMMAND_NAME
		else
			rm -f $TMP_COMMAND
			echo ">>> command file create failed!"
			exit 1
		fi
	else
		adb push $TMP_COMMAND $PACKAGE_DIR/$COMMAND_NAME
		echo "#!/system/bin/sh" > $TMP_SHELL
		echo "mkdir -p $COMMAND_DIR" >> $TMP_SHELL
		echo "cp $PACKAGE_DIR/$COMMAND_NAME $COMMAND_DIR/$COMMAND_NAME" >> $TMP_SHELL
		adb push $TMP_SHELL $PACKAGE_DIR/$TMP_SHELL
		rm -rf $TMP_SHELL
		adb shell chmod 777 $PACKAGE_DIR/$TMP_SHELL
		if echo "su < $PACKAGE_DIR/$TMP_SHELL; exit" | adb shell | grep "not found" > /dev/null 2>&1;then
			echo ">>> ERROR: Not a root phone, please root this device firstly"
			exit $ERR_DEVICE_NOT_ROOTED;
		fi
	fi
	echo ">>> Reboot to Recovery ..."
	adb reboot recovery
}

if [ $# != 1 ];then
	usage
fi
if [ ! -f $1 ];then
	echo ">>> $1 is not exists!"
	usage
fi

OTA_PATH=$1
OTA_DIR=$(dirname $OTA_PATH)
OTA_NAME=$(basename $OTA_PATH)

checkRootState
pushPackage
createCommand
