# !/bin/bash

PUBLIC_XML="$1"
FRAMEWORK_RES_APK="$2"
PRJ_TMP="$3"

APKTOOL=$PORT_ROOT/tools/apktool

echo "$@"

if [ -f $FRAMEWORK_RES_APK ];then
	tempDir=`mktemp -d "framework-res.XXXXXX"`
	$APKTOOL d -f $FRAMEWORK_RES_APK $tempDir 
#2>/dev/null
	if [ -f $tempDir/res/values/public.xml ];then
		cp $tempDir/res/values/public.xml $PUBLIC_XML
		#rm $tempDir -rf
		echo "SUCCESS get $PUBLIC_XML from $FRAMEWORK_RES_APK"
	else
		echo "ERROR: can't $PUBLIC_XML from $FRAMEWORK_RES_APK"
		rm $tempDir -rf
		exit 1
	fi
else
	echo "ERROR: $FRAMEWORK_RES_APK doesn't exist!!"
fi
