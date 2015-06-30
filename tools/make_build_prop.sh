#!/bin/bash

BOARD_PROP=""
VENDOR_PROP=""
OUT_PROP=""
help=""
TEMP_OUT_PROP=""

set -- `getopt "b:r:o:h:" "$@"`

while :
do
case "$1" in
    -b) shift; BOARD_PROP=$1 ;;
    -r) shift; VENDOR_PROP="$1";;
    -o) shift; OUT_PROP="$1";;
    -h) help=1;;
    --) break ;;
esac
shift
done
shift

#Update build.prop file
function update_build_prop()
{
    TKEYNAME="test-keys"
    RKEYNAME="release-keys"
    COUNT=1
    while read LINE
    do 
        if [ "$LINE" != "" -a "${LINE:0:1}" != "#" ];then
            LEFT=${LINE%%=*}
            LINENUM=$(grep -n "$LEFT" $TEMP_OUT_PROP)
            LINESTART=${LINENUM%%:*}
            RIGHT=${LINE##*=}

            if [ -z "$LINESTART" ];then
                if [ $COUNT -lt "2" ];then
                   ARROW="#Overrides build properties"
                   sed -i "$COUNT i $ARROW" $TEMP_OUT_PROP
                   COUNT=`expr $COUNT + 1`
                fi
                if [ "$RIGHT" = "delete" ];then
                    continue
                fi
                sed -i "$COUNT i $LINE" $TEMP_OUT_PROP
                COUNT=`expr $COUNT + 1`
            else
                if [ "x$LEFT" != "x" -a "x$RIGHT" != "x" ];then
                    if [ "$RIGHT" != "delete" ];then
                        sed -i "/$LEFT/d" $TEMP_OUT_PROP
                        sed -i "$LINESTART i $LINE" $TEMP_OUT_PROP
                    else
                        sed -i "/$LEFT/d" $TEMP_OUT_PROP
                    fi
                fi
            fi
        fi      
    done < $1

    sed -i "s/$RKEYNAME/$TKEYNAME/g" $TEMP_OUT_PROP
}

if [ ! -f "$BOARD_PROP" ];then
	echo ">>> WARNING: $BOARD_PROP doesn't exist!!";
	exit 0;
fi

if [ ! -f $VENDOR_PROP ];then
	echo ">>> ERROR: $VENDOR_PROP doesn't exist!!";
	exit 1;
fi

TEMP_OUT_PROP=`mktemp "/tmp/build.prop.XXXX"`
if [ -f $TEMP_OUT_PROP ];then
	cp $VENDOR_PROP $TEMP_OUT_PROP -rf;
	update_build_prop $BOARD_PROP;

	if [ ! -d `dirname $OUT_PROP` ];then
		mkdir -p `dirname $OUT_PROP`;
	fi
	mv $TEMP_OUT_PROP $OUT_PROP;
else
	echo ">>> ERROR: can't use mktemp to create temp file in /tmp";
	exit 1;
fi

