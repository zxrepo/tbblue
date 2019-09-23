#!/bin/bash
G_PROGRAM_NAME=nextpi-startup
. /opt/nextpi/bin/func/nextpi-globals

echo 
echo -n "NextPi - Building volatile RAM environment."
mkdir /ram/nextpi && echo -n "."
mkdir /tmp/.config && echo -n "."
echo " - done!"
echo "Launching NextPi - Dongle Interface Check and Keylock"
nextpi-admin_update

