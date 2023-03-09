#!/bin/sh

while :; do

while ! route | grep -q usb; do
sleep 5
done

autossh -M 20000 -N -T -R 0.0.0.0:2222:localhost:22 box@$1 -y -y
killall autossh

sleep 5
done

