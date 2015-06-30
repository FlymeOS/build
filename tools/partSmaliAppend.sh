#!/bin/bash

ONLY_PART=false

if [ $1 == "--onlypart" ]; then
	ONLY_PART=true
	shift
fi

PART_SMALI_DIR=$1
DST_SMALI_DIR=$2

echo ">>>> in partSmaliAppend.sh";

if [ ! -d $PART_SMALI_DIR ];then
	exit 0;
fi;

if [ ! -d $DST_SMALI_DIR ];then
	echo "<<<< ERROR: $DST_SMALI_DIR doesn't exsit!!";
	exit 1;
fi;


for file in `find $PART_SMALI_DIR -type f -name "*.part"`
do
	FILEPATH=${file##*/smali/};
	PARTFILE=$PART_SMALI_DIR/$FILEPATH;
	DSTFILE=$DST_SMALI_DIR/${FILEPATH%.part};

	if [ -f $DSTFILE ]; then
		FUNCS=$(cat $PARTFILE | grep "^.method")
		echo "$FUNCS" | while read func
		do
			functmp=$(echo "$func" | sed 's/\//\\\//g;s/\[/\\\[/g')
			TMP=$(sed -n "/$functmp/p" $DSTFILE)
			if [ x"$TMP" != x"" ];then
				echo "<<<< remove $func from $DSTFILE"
				sed -i "/^$functmp/,/^.end method/d" $DSTFILE
			fi
		done
	else
		DSTDIR=`dirname $DSTFILE`
		if [ ! -d $DSTDIR ]; then
			mkdir -p $DSTDIR
		fi
	fi

	echo "cat $PARTFILE >> $DSTFILE"
	cat $PARTFILE >> $DSTFILE
	echo "<<<< append $PARTFILE"
	echo "        to $DSTFILE"
done;

if [ $ONLY_PART == false ]; then
	for file in `find $PART_SMALI_DIR -type f -name "*.smali"`
	do
		FILEPATH=${file##*/smali/};
		PARTFILE=$PART_SMALI_DIR/$FILEPATH;
		DSTFILE=$DST_SMALI_DIR/$FILEPATH
		DSTDIR=`dirname $DSTFILE`

		if [ ! -d $DSTDIR ]; then
			mkdir -p $DSTDIR
		fi

		cp $file $DSTFILE
		echo "cp $PARTFILE to $DSTFILE"
	done;
fi

find $DST_SMALI_DIR -type f -name "*.part" | xargs rm -f
