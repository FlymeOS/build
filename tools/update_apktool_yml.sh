#!/bin/bash

APKTOOL_IF_FRAMEWORK_DIR=~/apktool/framework

function isFrameworkApk()
{
	apktoolYml=$1

	grep "isFrameworkApk" "$apktoolYml" | awk -F: '{print $2}' | sed 's/^[ \t]*//g;s/[ \t]*$//g'
}

function updateApktoolYml()
{
    local apktoolYml=$1
    local tags=$2
    local tagsName=""
    local lineNum=""

    if [ x"$tags" != x ];then
        tagsName="-$tags"
    fi
    
    #echo "tagsName:$tagsName"
    if [ -f $apktoolYml ];then
        #echo "APKTOOL_IF_FRAMEWORK_DIR: $APKTOOL_IF_FRAMEWORK_DIR"
	isFrwkApk=`isFrameworkApk "$apktoolYml"`
	if [ "$isFrwkApk" != "true" ];then
            for resApkFile in $(ls "$APKTOOL_IF_FRAMEWORK_DIR/" | sort -r | grep "^[0-9]*$tagsName.apk")
            do
               #echo "resApkFile: $resApkFile"
               fileBaseName=`basename $resApkFile`
               resId=${fileBaseName%$tagsName\.*}
               resIdMatch="- $resId"
               resIdMatch2="  - $resId"
               #echo "update $apktoolYml with $resIdMatch"
               fileMatch=$((grep -n "ids:" $apktoolYml) | awk '{print $1}')
               if [ "$fileMatch" ];then
                   lineNum=${fileMatch%%:*}
                   #echo "old lineNum: $lineNum"
                   lineNum=`expr $lineNum`
                   #echo "new lineNum: $lineNum"
                   sed -i "/$resIdMatch/d"  $apktoolYml
                   sed -i "$lineNum a $resIdMatch"  $apktoolYml
                   sed -i "s/$resIdMatch/$resIdMatch2/g" $apktoolYml
               fi      
            done

	    # TODO
            # If share library resources is detected in apk, this apk will be mark as "sharedLibrary: true",
            # and then, this apk is build back as share library which is wrong.
            # This is a bug of apktool 2.0, as a workaround, just mark sharedLibrary as false.
	    echo 'I/update_apktool_yml: Change "sharedLibrary: true" to "sharedLibrary: false" for non framework apk'
            sed -i "s/sharedLibrary: true/sharedLibrary: false/g" $apktoolYml
	fi
        if [ x"$tags" != x ];then
            sed -i '/tag\:/d' $apktoolYml
            sed -i "/ids:/ i tag: $tags" $apktoolYml
	    sed -i "s/tag: $tags/  tag: $tags/g" $apktoolYml
        fi
    else
        echo "ERROR: $apktoolYml doesn't exist!"
    fi
}

if [ $# != 0 ];then
	updateApktoolYml $1 $2
fi
