#!/bin/sh

PORT=$(cat /tmp/$1 | grep ttyUSB)
sleep 5
echo -e "AT^TMODE=3\r" | microcom -t 1000 /dev/$PORT
/etc/init.d/$1 restart
