# !/bin/bash

BOARD_OTA_ZIP="$1"
BOARD_PUBLIC_XML="$2"
APKTOOL=$PORT_ROOT/tools/apktool

echo "$@"

if [ -f $BOARD_OTA_ZIP ];then
	echo "start get public.xml from $BOARD_OTA_ZIP to $BOARD_PUBLIC_XML"
	if [ ! -d `dirname $BOARD_PUBLIC_XML` ];then
		mkdir -p `dirname $BOARD_PUBLIC_XML`
	fi
	rm -rf ./.tmp
	mkdir ./.tmp
	unzip -q  $BOARD_OTA_ZIP -d ./.tmp
	cd ./.tmp
	$APKTOOL d ./system/framework/framework-res.apk framework-res
	if [ $? != "0" ];then
		echo "ERROR: can not decode ./system/framework/framework-res.apk"
		exit 1
	fi
	cp -rf ./framework-res/res/values/public.xml $BOARD_PUBLIC_XML
	cd - > /dev/null
	rm -rf ./.tmp
	exit 0
fi
