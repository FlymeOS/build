#!/bin/bash
#**************************************************#
#This shell used to generate public.xml map table
#between the oem and with board's feature public.xml 
#It also update the new add id to com.android.
#internal.R.java			      	
#**************************************************#


#constant values
dummyfilter="APKTOOL_DUMMY"

internaldir="smali/com/android/internal"
flag="# direct methods"

GENMAP_PY="$PORT_BUILD/tools/GenMap.py"
UPDATE_INTERNAL_JAVA_PY="$PORT_BUILD/tools/UpInterrJava.py"


function removefile()
{
	if [ -f $1 ];
	then
		rm $1
	fi
}

#To delete the apktools dummy files
function dummyfilter()
{
	sed -i "/$dummyfilter/d" $1
}

#to update smali/com/android/internal/R*.smali
function upinterrjava()
{
        $UPDATE_INTERNAL_JAVA_PY $1 "$2/$internaldir"
}

function genmap() 
{
	mergeout=`mktemp /tmp/mergeout.XXXX`
	mergenone=`mktemp /tmp/mergenone.XXXX`
	mergeadd=`mktemp /tmp/mergeadd.XXXX`

	# use python to generate the merge_update.txt merge_none.txt and merge_add.txt
	$GENMAP_PY -map $2 $3 $mergeout $mergenone
	if [ $? != "0" ];then
		echo "ERROR, can not generate the map $mergeout $mergenone"
		exit 1
	fi

	$GENMAP_PY -add $1 $2 $mergeadd
	if [ $? != "0" ];then
		echo "ERROR, can not generate the map $mergeadd"
		exit 1
	fi

	dummyfilter $mergeout;
	dummyfilter $mergenone;
	dummyfilter $mergeadd;

	rm -f $4/merge_update.txt
	rm -f $4/merge_none.txt
	rm -f $4/merge_add.txt

	cp $mergeout $4/merge_update.txt
	cp $mergenone $4/merge_none.txt
	cp $mergeadd $4/merge_add.txt

	echo "OK,finish!"
}

function defaultall()
{
	genmap $1 $2 $3;
	upinterrjava $mergeadd $4;
}

function usage()
{
	echo "usage: ./diffmap.sh -map public_oem.xml public_oem_update.xml public_master.xml out_dir"
	echo "          	      generate the ID map tabel"
	echo "       ./diffmap.sh -add merge_add.txt framework.jar.out"
	echo "          	      merge merge_add.txt table to framework.jar.out/smali/com/android/internal/R*.smali"
	echo "       ./diffmap.sh -all public_oem.xml public_oem_update.xml public_master.xml framework.jar.out"
	echo "           	      generate map tabel and merge merge_add.txt table to framework.jar.out"
}

if [  "$#" -lt "3" ]
then
    usage;
    exit 0
fi

if [ $1 = "-map" -a "$#" -eq "5" ];
then
	genmap $2 $3 $4 $5;
else if [ $1 = "-all" -a "$#" -eq "5" ];
then
	defaultall $2 $3 $4 $5;
else if [ $1 = "-add" -a "$#" -eq "3" ];
then
	upinterrjava $2 $3;
else
	echo "Parameter is wrong!!!"
	usage;
       exit 0
fi
fi
fi
