#!/bin/bash

# usage: use apktool to install the framework-res.apk
# eg: ifdir system/framework [board/origin/xxxx]

function install_frameworks()
{
    local options=""
    [ ! -z $2 ] && options="$options -t $2"
    [ ! -z $3 ] && options="$options -p $3" && mkdir -p $3

    mkdir -p ~/.local/share/apktool/framework

    for res_apk in `find $1 -name "*.apk"`;
    do
        # TODO apktool 2.0
        $PORT_ROOT/tools/apktool if $options $res_apk

        # apktool 1.5
        # $PORT_ROOT/tools/apktool if -t $res_apk $2

    done
}

if [ $# != 0 ];then
	install_frameworks $1 $2 $3
fi
