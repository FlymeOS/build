#!/bin/bash

TARGET_FILES_DIR=$1
SYSTEM_DIR=$TARGET_FILES_DIR/SYSTEM

function custom_flymeRes()
{
    if [ -f $SYSTEM_DIR/framework/flyme-res/flyme-res.apk ]; then
        mv $SYSTEM_DIR/framework/flyme-res/flyme-res.apk $SYSTEM_DIR/framework/flyme-res/flyme-res.jar
    fi
}

custom_flymeRes
