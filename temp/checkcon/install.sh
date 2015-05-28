#!/bin/bash

dir_script=`dirname $0`
dir_data="$dir_script/data"

mkdir -p /usr/etc/checkcon
cp $dir_data/Lost_connection.png /usr/etc/checkcon/

cp $dir_data/checkcon /usr/bin/
