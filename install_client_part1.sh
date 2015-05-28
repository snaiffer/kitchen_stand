#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"
dir_libs="$dir_script/libs"
source $dir_libs/general.sh

printf "Setting for OS... "
# turn off mls. You need to reboot after it
zadm security-mode off
sed -i "/pam_gnome_keyring.so/d" /etc/pam.d/lxdm
check_status

reboot_request
