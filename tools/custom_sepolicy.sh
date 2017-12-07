#!/bin/bash

#################################################################################################
# Add the new rules in the sepolicy.                                                            #
# The script will inject the rules into the sepolicy, better ensure the device security.        #
# If you are familiar with the sepolicy rules, you can customize them in your device.           #
#################################################################################################

PRJ_ROOT=`pwd`
SEPOLICY_INJECT=$PORT_ROOT/build/tools/sepolicy-inject/sepolicy-inject-v2
SEPOLICY=$1

if [ ! -f $SEPOLICY ] || [ x"$SEPOLICY" = x ]; then
    echo "USAGE: sepolicy_injecy <sepolicy file>"
    exit 1
fi

$SEPOLICY_INJECT -z flymed_exec -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z flymed_socket -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -s flymed_socket -t tmpfs -c filesystem -p associate -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s init -t flymed_exec -c file -p execute,execute_no_trans -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s init -t flymed_socket -c sock_file -p create,setattr -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s init -t init -c rawip_socket -p getopt,create,setopt -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t flymed_socket -c sock_file -p write -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s init -t system_file -c file -p execute_no_trans -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -z flyme_statusbar_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z networkmanagement_service_flyme_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z move_window_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z access_control_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z flyme_theme_manager_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z flyme_wallpaper_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z flyme_packagemanager_service -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -z alphame_service -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -s system_server -t flyme_statusbar_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t networkmanagement_service_flyme_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t move_window_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t access_control_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t flyme_theme_manager_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t flyme_wallpaper_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t flyme_packagemanager_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_server -t alphame_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -s platform_app -t access_control_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t flyme_wallpaper_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t flyme_packagemanager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t flyme_statusbar_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t alphame_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t move_window_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t networkmanagement_service_flyme_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s platform_app -t flyme_theme_manager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -s system_app -t access_control_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t alphame_service -c service_manager -p add,find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t flyme_packagemanager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t flyme_wallpaper_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t flyme_theme_manager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t move_window_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t networkmanagement_service_flyme_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s system_app -t flyme_statusbar_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1

$SEPOLICY_INJECT -s untrusted_app -t access_control_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t flyme_packagemanager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t alphame_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t move_window_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t flyme_theme_manager_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t networkmanagement_service_flyme_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t flyme_wallpaper_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1
$SEPOLICY_INJECT -s untrusted_app -t flyme_statusbar_service -c service_manager -p find -P $SEPOLICY > /dev/null 2>&1

if [ -f $PRJ_ROOT/custom_sepolicy.sh ]; then
    echo "Run $PRJ_ROOT/custom_sepolicy.sh ..."
    source $PRJ_ROOT/custom_sepolicy.sh $SEPOLICY_INJECT $SEPOLICY
    echo "Run $PRJ_ROOT/custom_sepolicy.sh done"
fi
