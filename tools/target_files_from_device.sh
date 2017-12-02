#!/bin/bash 
################################################################################################################
# Option:     target, ota;                                                                                     #
# target:     This shell will pull files from phone, build apkcerts.txt and filesystem_config.txt from device, #
# create linkinfo.txt from device and recover the device files' symlink information in target_file, then       #
# generate a target zip file.                                                                                  #
# ota:        This shell will build a ota package from the target file.                                        #
# ota_block:  This shell will build a ota package from the target file.                                        #
################################################################################################################

PRJ_ROOT=`pwd`
ADB="adb"

CHECK_SU=$PORT_ROOT/tools/check-su

TOOL_DIR=$PORT_BUILD/tools
TARGET_FILES_TEMPLATE_DIR=$PORT_BUILD/target_files_template
OTA_FROM_TARGET_FILES=$TOOL_DIR/releasetools/ota_from_target_files
ADD_IMG_TO_TARGET_FILES=$TOOL_DIR/releasetools/add_img_to_target_files
SYSTEM_INFO_PROCESS=$TOOL_DIR/releasetools/systeminfoprocess.py
RECOVERY_LINK=$TOOL_DIR/releasetools/recoverylink.py
GET_INFO_FROM_SCRIPT=$TOOL_DIR/getInfoFromScript.py

OUT_DIR=$PRJ_ROOT/out
OUT_OTA_DIR=$OUT_DIR/ota
OUT_OTA_SYSTEM=$OUT_OTA_DIR/system
OUT_OTA_METAINF=$OUT_OTA_DIR/META-INF

OEM_TARGET_DIR=$OUT_DIR/oem_target_files
SYSTEM_DIR=$OEM_TARGET_DIR/SYSTEM
META_DIR=$OEM_TARGET_DIR/META
RECOVERY_ETC_DIR=$OEM_TARGET_DIR/RECOVERY/RAMDISK/etc

OTA_PACKAGE=$PRJ_ROOT/ota.zip
OEM_TARGET_ZIP=$OUT_DIR/oem_target_files.zip
VENDOR_TARGET_ZIP=$OUT_DIR/vendor_target_files.zip
OUTPUT_OTA_PACKAGE=$OUT_DIR/vendor_ota.zip

FROM_OTA=0
ROOT_STATE="system_root"

######## Error Exit Num ##########
ERR_USB_NOT_CONNECTED=151
ERR_DEVICE_NOT_ROOTED=152

ERR_NOT_PREPARE_RECOVERY_FSTAB=201
ERR_NOT_OTA_PACKAGE=202
ERR_OTA_INCOMPATIBLE=203
ERR_NOT_VENDOR_TARGET=204
ERR_MISSION_FAILED=209

# check for files preparing
function checkForEnvPrepare {
    echo ">> check essential files existing ..."
    if [ ! -f $PRJ_ROOT/recovery.fstab ];then
        echo "<< ERROR: Can not find $PRJ_ROOT/recovery.fstab!!"
        exit $ERR_NOT_PREPARE_RECOVERY
    fi
    $ADB shell ls / > /dev/null 2>&1
    if [ $? != 0 -a -f $OTA_PACKAGE ];then
        echo "<< Device is not online, but ota.zip is exist."
        echo "<< Config Makefile from $OTA_PACKAGE."
        FROM_OTA=1
    fi
    echo "<< check essential files existing done"
}

# wait for the device to be online or timeout
function waitForDeviceOnline {
    echo ">> Wait for the device to be online..."
    local timeout=30
    while [ $timeout -gt 0 ]
    do
        if adb shell ls /system > /dev/null 2>&1; then
            echo "<< device is online"
            break
        fi
        echo ">> device is not online, wait .."
        sleep 3
        timeout=$[$timeout - 3]
    done
    if [ $timeout -eq 0 ];then
        echo "<< ERROR: Please ensure adb can find your device and then rerun this script!!"
        exit $ERR_USB_NOT_CONNECTED
    fi
}

# check system root state
function checkRootState {
    echo ">> Check root state of phone ..."
    waitForDeviceOnline
    SECURE_PROP=$(adb shell getprop ro.secure)
    DEBUG_PROP=$(adb shell getprop ro.debuggable)

    $CHECK_SU
    local ret=$?
    if [ $ret == 0 ]; then
        ROOT_STATE="system_root"
    elif [ x"$SECURE_PROP" = x"0" -o x"$DEBUG_PROP" = x"1" ];then
        ROOT_STATE="kernel_root"
        adb root
        waitForDeviceOnline
    else
        echo "<< ERROR: Not a root phone, please root this device firstly!!"
        exit $ERR_DEVICE_NOT_ROOTED;
    fi

    echo "<< Check root state of phone done."
    echo "* ROOT_STATE=$ROOT_STATE"
    echo " "
}

# copy the whole target_files_template dir
function copyTargetFilesTemplate {
    echo ">> copy $TARGET_FILES_TEMPLATE_DIR to $OEM_TARGET_DIR ..."
    rm -rf $OEM_TARGET_DIR
    rm -f $OEM_TARGET_ZIP
    mkdir -p $OEM_TARGET_DIR
    if [ x"$IS_AB_SYSTEM" = x"true" ]; then
        cp -r $PORT_BUILD/target_files_template_AB/* $OEM_TARGET_DIR
    else
        cp -r $TARGET_FILES_TEMPLATE_DIR/* $OEM_TARGET_DIR
    fi
    echo "<< copy $TARGET_FILES_TEMPLATE_DIR to $OEM_TARGET_DIR ..."
}

# update system partition size
#################################################################################################
# This function is used to get the size of the system partition.                                #
# If you have built the device, you can refer to the following commands                         #
# through the adb shell to get the correct partition information.                               #
#################################################################################################
# shell@Flyme:/ #su                                                                             #
#                                                                                               #
# root@Flyme :/ #mount                                                                          #
# *** Find the system mount ==> /dev/block/platform/mtk-msdc.0/by-name/system ***               #
#                                                                                               #
# root@Flyme :/ ls -l /dev/block/platform/mtk-msdc.0/by-name/system                             #
# *** Find the system corresponding to the mount point ==> system -> /dev/block/mmcblk0p28 ***  #
#                                                                                               #
# root@Flyme :/ cat proc/partitions                                                             #
# *** Find the block size of system ==> 3989504 mmcblk0p28 ***                                  #
# *** SystemPartitionSize = 3989504 * 1024 ==> 0xF3800000 ***                                   #
# *** Fill in the value to the vendor/META/misc_info.txt in your device. ***                    #
#################################################################################################
function updateSystemPartitionSize {
    echo ">> get system partition size ..."
    if [ x"$IS_AB_SYSTEM" = x"true" ]; then
        echo ">> Is A/B System Device"
        slot_suffix=$(adb shell getprop ro.boot.slot_suffix)
        if [ x"$slot_suffix" = x ]; then
            slot_suffix="_a"
        fi
    fi
    if [ "$ROOT_STATE" = "system_root" ]; then
        SYSTEM_MOUNT_POINT=$(adb shell su -c find /dev/block/ -name system$slot_suffix)
        SYSTEM_SOFT_MOUNT_POINT=$(adb shell su -c ls -l $SYSTEM_MOUNT_POINT | awk -F '->' '{print $2}' | awk -F '/' '{print $NF}')
    else
        waitForDeviceOnline
        SYSTEM_MOUNT_POINT=$(adb shell find /dev/block/ -name "system"$slot_suffix)
        SYSTEM_SOFT_MOUNT_POINT=$(adb shell ls -l $SYSTEM_MOUNT_POINT | awk -F '->' '{print $2}' | awk -F '/' '{print $NF}')
    fi
    SYSTEM_PARTITION_SIZE=$(adb shell cat proc/partitions | grep $SYSTEM_SOFT_MOUNT_POINT | awk 'BEGIN{FS=" "}{print $3}')
    if [ x"$SYSTEM_PARTITION_SIZE" = x ] || [ -z "$(echo $SYSTEM_PARTITION_SIZE | sed -n "/^[0-9]\+$/p")" ]; then
        echo "system partition size get error!"
        return;
    fi
    SYSTEM_PARTITION_SIZE=$[$SYSTEM_PARTITION_SIZE * 1024]
    SYSTEM_PARTITION_SIZE16=`echo "obase=16;$SYSTEM_PARTITION_SIZE"|bc`
    #echo "system partition size is 0x$SYSTEM_PARTITION_SIZE16"
    if [ x"$SYSTEM_PARTITION_SIZE16" != x ]; then
        sed -i "s/system_size.*/system_size\=0x$SYSTEM_PARTITION_SIZE16/g" $OEM_TARGET_DIR/META/misc_info.txt
    fi
    echo "<< get system partition size ..."
}


# get system files info from phone
function buildSystemInfo {
    echo ">> get filesystem_config.txt from phone ..."
    waitForDeviceOnline
    adb push $TOOL_DIR/releasetools/getfilesysteminfo.sh /data/local/tmp

    # Create a new /data/local/tmp/file.info
    adb shell rm /data/local/tmp/file.info
    adb shell touch /data/local/tmp/file.info
    adb shell chmod 666 /data/local/tmp/file.info

    waitForDeviceOnline
    if [ "$ROOT_STATE" = "system_root" ];then
        #adb push $TOOL_DIR/releasetools/getsysteminfocommand /data/local/tmp
        #echo "su < /data/local/tmp/getsysteminfocommand; exit" | adb shell
        adb shell su -c /data/local/tmp/getfilesysteminfo.sh

    else
        adb shell chmod 0777 /data/local/tmp/getfilesysteminfo.sh
        adb shell /data/local/tmp/getfilesysteminfo.sh
    fi

    adb pull /data/local/tmp/file.info $META_DIR/
    $SYSTEM_INFO_PROCESS $META_DIR/file.info $META_DIR/system.info $META_DIR/link.info

    cat $META_DIR/system.info | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/filesystem_config.txt
    cat $META_DIR/link.info   | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/linkinfo.txt

    if [ ! -f $META_DIR/filesystem_config.txt -o ! -f $META_DIR/linkinfo.txt ];then
        echo "<< ERROR: Failed to create filesystem_config.txt or linkinfo.txt!!"
        exit $ERR_MISSION_FAILED
    fi

    rm -f $META_DIR/file.info $META_DIR/system.info $META_DIR/link.info
    echo "<< get filesystem_config.txt from phone done"
    echo "* out ==> $META_DIR/filesystem_config.txt"
    echo " "
}

# get system files info from phone
function buildSystemDir_dd {
    echo ">> dd system from device (time-costly, be patient) ..."
    waitForDeviceOnline
    if [ "$ROOT_STATE" = "system_root" ];then
        adb shell su -c dd if=$SYSTEM_MOUNT_POINT of=/sdcard/system.img bs=2048 > /dev/null 2>&1
    else
        adb shell dd if=$SYSTEM_MOUNT_POINT of=/sdcard/system.img bs=2048 > /dev/null 2>&1
    fi
    adb pull /sdcard/system.img $OUT_DIR/system.img  > /dev/null 2>&1
    adb shell rm /sdcard/system.img
    unpack_systemimg $OUT_DIR/system.img $SYSTEM_DIR
    if [ x"$IS_AB_SYSTEM" = x"true" ]; then
        mv $SYSTEM_DIR $OEM_TARGET_DIR/ROOT
        mv $OEM_TARGET_DIR/ROOT/system $SYSTEM_DIR
        mkdir $OEM_TARGET_DIR/ROOT/system
        rm -f $SYSTEM_DIR/lost+found
    fi
    echo "<< dd system from device (time-costly, be patient) done"
    echo " "
}

function unpack_systemimg {
    local systemimg=$1
    local outdir=$2

    if [ "x$systemimg" = "x" ]; then
        return 1
    fi

    echo ">>> begin unpack $systemimg"
    if [ "x$outdir" = "x" ]; then
        outdir=$PWD
    fi

    if [ -f $systemimg ]; then
        mkdir -p $outdir
        tmpMnt=`mktemp -dt system.XXXX.mnt`
        sudo mount -t ext4 -o loop $systemimg $tmpMnt

        sudo cp -rf $tmpMnt/* $outdir
        sudo umount $tmpMnt
        sudo chmod 777 -R $outdir

        rm -rf $tmpMnt

        echo ">>> success unpack $systemimg to $outdir"
        return 0
    else
        echo ">>> $systemimg doesn't exist! "
    fi

    echo ">>> failed to unpack $systemimg"
    return 1
}

# build apkcerts.txt from packages.xml
function buildApkcerts {
    echo ">> build apkcerts.txt from device ..."
    if [ x"$ROOT_STATE" = x"system_root" ];then
        adb shell su -c "chmod 666 /data/system/packages.xml"
        adb shell su -c "cat /data/system/packages.xml" > $OEM_TARGET_DIR/packages.xml
    else
        adb shell chmod 666 /data/system/packages.xml
        adb shell cat /data/system/packages.xml > $OEM_TARGET_DIR/packages.xml
    fi

    python $TOOL_DIR/apkcerts.py $OEM_TARGET_DIR/packages.xml $META_DIR/apkcerts.txt
    cat $META_DIR/apkcerts.txt | sort > $META_DIR/temp.txt
    mv $META_DIR/temp.txt $META_DIR/apkcerts.txt
    rm -f $OEM_TARGET_DIR/packages.xml
    if [ ! -f $META_DIR/apkcerts.txt ];then
        echo "<< ERROR: Failed to create apkcerts.txt!!"
        exit $ERR_MISSION_FAILED
    fi
    echo "<< build apkcerts.txt from device done"
    echo "* out ==> $META_DIR/apkcerts.txt"
    echo " "
}

# recover the device files' symlink information
function recoverSystemSymlink {
    echo ">> recover link for $OEM_TARGET_DIR ..."
    $RECOVERY_LINK $META_DIR/linkinfo.txt $OEM_TARGET_DIR
    echo "<< recover link for $OEM_TARGET_DIR done"
}

function turnModToNum {
    mod=$1
    ((num=2#$(echo $mod | sed 's/[^\-]/1/g; s/\-/0/g')))
    echo $num
}

function addReadMod {
    sFile=$1

    sFileMod=$(adb shell ls -l $sFile | awk '{print $1}')
    ownMod=${sFileMod:1:3}
    grpMod=${sFileMod:4:3}
    otherMod="r"${sFileMod:8:2}

    newMod=$(turnModToNum $ownMod)$(turnModToNum $grpMod)$(turnModToNum $otherMod)

    echo "Set $sFile to be readable"
    if [ "x$newMod" != "x" ];then
        if [ x"$ROOT_STATE" = x"system_root" ]; then
            adb shell su -c "mount -o remount,rw /system";
	    adb shell su -c "chmod $newMod $sFile";
        else
	    adb shell mount -o remount,rw /system;
	    adb shell chmod $newMod $sFile;
        fi
    fi

}

function pullFailedFailes {
    failedLog=$1
    times=$2
    tmpLog=$(mktemp -t "tmp.pull.XXXXX")

    echo ">>> pullFailedFailes again with su-pull ..."
    grep "^failed to copy" $failedLog | while read LINE
    do
        sFile=$(echo $LINE | awk -F \' '{print $2}')
        outFile=$(echo $LINE | awk -F \' '{print $4}')

        addReadMod $sFile
        su-pull $sFile $outFile 2>&1 | grep "^failed to copy" | tee $tmpLog
    done

    grep "^remote object" $failedLog | while read LINE
    do
        sFile=$(echo $LINE | awk -F \' '{print $2}')
        outFile=$SYSTEM_DIR/$(echo $sFile | awk 'BEGIN { FS="/system/" } {print $NF}')

        addReadMod $sFile
        su-pull $sFile $outFile
    done

    if [ $(test -s $tmpLog) ]; then
         times=$(expr $times - 1)
         if [ $times -gt 0 ]; then
             pullFailedFailes $tmpLog
         else
             cat $tmpLog > $OUT_DIR/system-pull-failed.log
         fi
    fi
    rm $tmpLog
    echo "<<< pullFailedFailes again with su-pull done"
}

function dealwithSystemPullLog {
    pullLog=$1
    pullFailedFailes $pullLog 20
    if [ -s $OUT_DIR/system-pull-failed.log ];then
        echo "-------------------------------------------------------" > $OUT_DIR/build-info-to-user.txt
        echo "Some files those pull failed you must deal with manually:" >> $OUT_DIR/build-info-to-user.txt
        cat $OUT_DIR/system-pull-failed.log | sed -e "s/.*out\/oem_target_files\/SYSTEM\/\(.*\)'.*/\1/" >> $OUT_DIR/build-info-to-user.txt
        echo "" >> $OUT_DIR/build-info-to-user.txt
        echo "---------" >> $OUT_DIR/build-info-to-user.txt
        echo "pull log:" >> $OUT_DIR/build-info-to-user.txt
        cat $OUT_DIR/system-pull-failed.log >> $OUT_DIR/build-info-to-user.txt
        echo "-------------------------------------------------------" >> $OUT_DIR/build-info-to-user.txt
    fi
}

function pullSpecialSelabelFile {
    echo ">>> pullSpecialSelabelFile with su-pull ..."
    tmpLog=$(mktemp -t "tmp.pull.XXXXX")
    cat $META_DIR/filesystem_config.txt | while read LINE
    do
        system_file=$(echo $LINE | grep "system_file")
        if  [ "x$system_file" = "x" ];then
            sFile=$(echo $LINE | awk -F " " '{print "/" $1}')
            outFile=$SYSTEM_DIR/$(echo $sFile | awk 'BEGIN { FS="/system/" } {print $NF}')
            addReadMod $sFile
            su-pull $sFile $outFile 2>&1 | tee -a $tmpLog
        fi
    done
    cat $tmpLog >> $OUT_DIR/system-pull.log
    rm $tmpLog
    echo "<<< pullSpecialSelabelFile with su-pull done"
}

# build the SYSTEM dir under target_files
function buildSystemDir {
    echo ">> retrieve whole /system from device (time-costly, be patient) ..."
    adb pull /system $SYSTEM_DIR 2>&1 | tee $OUT_DIR/system-pull.log
    pullSpecialSelabelFile
    find $SYSTEM_DIR -name su | xargs rm -f
    find $SYSTEM_DIR -name .suv | xargs rm -f
    find $SYSTEM_DIR -name invoke-as | xargs rm -f
    dealwithSystemPullLog $OUT_DIR/system-pull.log
    echo "<< retrieve whole /system from device (time-costly, be patient) done"
}


# prepare boot.img recovery.fstab for target
function prepareBootRecovery {
    echo ">> prepare boot.img and recovery.img ..."
    if [ -f $PRJ_ROOT/boot.img ];then
        mkdir -p $OEM_TARGET_DIR/IMAGES
        cp -f $PRJ_ROOT/boot.img $OEM_TARGET_DIR/IMAGES/boot.img
        echo ">>> Copy boot.img to $OEM_TARGET_DIR/IMAGES/boot.img"
    fi
    if [ ! -d $RECOVERY_ETC_DIR ];then
        mkdir -p $RECOVERY_ETC_DIR
    fi
    cp -f $PRJ_ROOT/recovery.fstab $RECOVERY_ETC_DIR/recovery.fstab
    echo ">>> Copy recovery.fstab to $RECOVERY_ETC_DIR/recovery.fstab"
    echo "<< prepare boot.img and recovery.img done"
}

# compress the target_files dir into a zip file
function zipTargetFiles {
    echo ">> zip $OEM_TARGET_ZIP from $OEM_TARGET_DIR ..."
    cd $OEM_TARGET_DIR
    zip -q -r -y $OEM_TARGET_ZIP *
    cd -
    #rm -rf $OEM_TARGET_DIR
    if [ ! -f $OEM_TARGET_ZIP ];then
        echo "<< ERROR: Failed to create $OEM_TARGET_ZIP!!"
        exit $ERR_MISSION_FAILED
    fi
    echo "<< zip $OEM_TARGET_ZIP from $OEM_TARGET_DIR done"
}

# pull files and info from phone and build a target file
function targetFromPhone {
    checkRootState
    copyTargetFilesTemplate
    updateSystemPartitionSize

    #buildSystemInfo
    buildApkcerts
    #buildSystemDir
    buildSystemDir_dd
    #recoverSystemSymlink

    prepareBootRecovery
    zipTargetFiles
}

# check for files preparing [from package]
function checkOtaPackage {
    echo ">> check $OTA_PACKAGE ..."
    if [ ! -f $OTA_PACKAGE ];then
        echo "<< ERROR: Can not find $OTA_PACKAGE!!"
        exit $ERR_NOT_OTA_PACKAGE
    fi
    [ -e $OUT_OTA_DIR ] && rm -rf $OUT_OTA_DIR
    [ ! -e $OUT_DIR ] && mkdir -p $OUT_DIR
    echo ">>> unzip $OTA_PACKAGE to $OUT_OTA_DIR ..."
    unzip -q $OTA_PACKAGE -d $OUT_OTA_DIR
    echo "<<< unzip $OTA_PACKAGE to $OUT_OTA_DIR done"
    if [ ! -e $OUT_OTA_SYSTEM -o ! -e $OUT_OTA_METAINF ];then
        echo "<< ERROR: Can not find $OUT_OTA_SYSTEM or $OUT_OTA_METAINF!!"
        echo "   Please check whether $PRJ_ROOT/ota.zip is a complete ota package"
        exit $ERR_OTA_INCOMPATIBLE
    fi
}

# get system files info from META in ota package
function buildSystemInfoFromPackage {
    echo ">> get system files info from package ..."
    mkdir -p $META_DIR
    $GET_INFO_FROM_SCRIPT $OUT_OTA_DIR $META_DIR/system.info $META_DIR/link.info

    if [ ! -f $META_DIR/system.info -o ! -f $META_DIR/link.info ];then
        echo "<< ERROR: Failed to create system.info or link.info!!"
        exit $ERR_MISSION_FAILED
    fi

    cat $META_DIR/system.info | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/filesystem_config.txt
    cat $META_DIR/link.info   | sed '/\bsuv\b/d;/\bsu\b/d;/\binvoke-as\b/d' | sort > $META_DIR/linkinfo.txt

    if [ ! -f $META_DIR/filesystem_config.txt -o ! -f $META_DIR/linkinfo.txt ];then
        echo "<< ERROR: Failed to create filesystem_config.txt or linkinfo.txt!!"
        exit $ERR_MISSION_FAILED
    fi

    rm -f $META_DIR/system.info $META_DIR/link.info
    echo "<< get system files info from package done"
}

# build apkcerts just use platform key
function buildApkcertsFromPackage {
    echo ">> build apkcerts.txt ..."
    find $OUT_OTA_SYSTEM -name "*.apk" > $META_DIR/app.list
    [ -e $META_DIR/apkcerts.txt ] && rm -f $META_DIR/apkcerts.txt
    cat $META_DIR/app.list | while read line
    do
        apkname=$(basename $line)
        echo "name=\"$apkname\" certificate=\"build/security/platform.x509.pem\" private_key=\"build/security/platform.pk8\"" >> $META_DIR/apkcerts.txt
    done
    rm -f $META_DIR/app.list
    echo "<< build apkcerts.txt done"
}

# build system dir from ota package
function buildSystemDirFromPackage {
    echo ">> build system dir from package ..."
    mkdir -p $SYSTEM_DIR
    rm -rf $SYSTEM_DIR/*
    mv $OUT_OTA_SYSTEM/* $SYSTEM_DIR/
    echo "<< build system dir from package done"
}

# get files and info from ota package and build a target file
function targetFromPackage {
    checkOtaPackage
    copyTargetFilesTemplate

    buildSystemInfoFromPackage
    buildApkcertsFromPackage
    buildSystemDirFromPackage
    recoverSystemSymlink

    prepareBootRecovery
    zipTargetFiles
}

# build a new full ota package
function buildOtaPackage {
    echo ">> build ota package from target-files $VENDOR_TARGET_ZIP ..."
    if [ ! -f $VENDOR_TARGET_ZIP ];then
        echo "<< ERROR: Can not find $VENDOR_TARGET_ZIP!!"
        exit $ERR_NOT_VENDOR_TARGET
    fi
    if [ x"$IS_AB_SYSTEM" = x"true" ]; then
        $ADD_IMG_TO_TARGET_FILES -a $VENDOR_TARGET_ZIP
    fi
    if [ x"$1" = x"block" ];then
        $OTA_FROM_TARGET_FILES -v --no_prereq --block -k $PORT_ROOT/build/security/testkey $VENDOR_TARGET_ZIP $OUTPUT_OTA_PACKAGE
    else
        $OTA_FROM_TARGET_FILES -v --no_prereq -k $PORT_ROOT/build/security/testkey $VENDOR_TARGET_ZIP $OUTPUT_OTA_PACKAGE
    fi
    if [ ! -f $OUTPUT_OTA_PACKAGE ];then
        echo "<< ERROR: Failed to build $OUTPUT_OTA_PACKAGE!!"
        exit $ERR_MISSION_FAILED
    fi
    echo "<< build ota package from target-files $VENDOR_TARGET_ZIP done"
}

function usage {
    echo "Usage: $0 target/ota"
    echo "      targe       -- create target files from phone or package"
    echo "      ota         -- build ota from target"
    echo "      ota_block   -- build block ota from target"
    exit $ERR_MISSION_FAILED
}

IS_AB_SYSTEM=$2

if [ $# -lt 1 ];then
    usage
elif [ "$1" = "target" ];then
    checkForEnvPrepare
    if [ $FROM_OTA = 0 ];then
        targetFromPhone
    else
        targetFromPackage
    fi
elif [ "$1" = "ota" ];then
    buildOtaPackage
elif [ "$1" = "ota_block" ];then
    buildOtaPackage block
else
    usage
fi
