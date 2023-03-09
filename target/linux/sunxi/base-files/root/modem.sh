#!/bin/sh

while :; do
sleep 10

if [ -z $RESET ]; then

while [ ! -d /sys/bus/usb/devices/$1 ]; do
	sleep 1
done

for i in 0 1 2 3 4; do
if [ -d /sys/bus/usb/devices/$1/$1:2.$i/net ]; then
	INTERFACE=$(ls /sys/bus/usb/devices/$1/$1:2.0/net | grep "usb[0-9]")
	break
fi
done

for i in 0 1 2 3 4; do
PORT=$(ls /sys/bus/usb/devices/$1/$1:2.$i | grep "ttyUSB[0-9]*")
if [ ! -z $PORT ]; then
	if echo -e "AT\r" | microcom -t 1000 /dev/$PORT | grep OK; then
		break
	fi
fi
done

iptables -t mangle -A POSTROUTING -o $INTERFACE -j TTL --ttl-set 64

echo $PORT > /tmp/$2
echo $INTERFACE >> /tmp/$2
echo "Modem $2 : PORT: $PORT LAN: $INTERFACE"
RESET="started"

fi

echo -e "AT^HCSQ?\r" | microcom -t 1000 /dev/$PORT | grep "HCSQ:" > /tmp/${INTERFACE}_$2.stat
echo -e "AT^SYSINFOEX\r" | microcom -t 1000 /dev/$PORT | grep "SYSINFOEX:" >> /tmp/${INTERFACE}_$2.stat

if ! grep -q "HCSQ\|\|SYSINFOEX" /tmp/${INTERFACE}_$2.stat; then 
	echo "Modem $2 : NO STATUS INFORMATION" 
	continue
fi

if grep -q "SYSINFOEX: *[0-9],[0-9],[0-9],255," /tmp/${INTERFACE}_$2.stat; then
	echo "Modem $2 : NO SIM CARD"
	echo -e "AT^TMODE=3\r" | microcom -t 1000 /dev/$PORT
	echo "Modem $2 : RESET"
	CONNECTED=""
	RESET=""
	rm /tmp/${INTERFACE}_$2.stat
	sleep 10
	continue
fi

if grep -q "NO SERVICE" /tmp/${INTERFACE}_$2.stat; then
	echo "Modem $2 : NO SERVICE"
	echo -e "AT^NDISDUP=1,0\r" | microcom -t 1000 /dev/$PORT
	CONNECTED=""
	if echo -e "AT+CFUN?\r" | microcom -t 1000 /dev/$PORT | grep -q "+CFUN: *0"
	then
		echo -e "AT^TMODE=3\r" | microcom -t 1000 /dev/$PORT
		echo "Modem $2 : RESET"
		RESET=""
		rm /tmp/${INTERFACE}_$2.stat
		sleep 10
	fi
	continue
fi
	
if [ -z "$CONNECTED" ]; then
	echo "Modem $2 : CONNECTING"
	echo -e "AT^NDISDUP=1,1,\"internet\"\r" | microcom -t 1000 /dev/$PORT
	CONNECTED="connected"
	ifdown $INTERFACE
	ifup $INTERFACE
	#tc qdisc add dev $INTERFACE root handle 1: htb
	#tc class add dev $INTERFACE parent 1: classid 1:1 htb rate 10Mbit
	continue
else
	if echo -e "AT^NDISSTATQRY?\r" | microcom -t 1000 /dev/$PORT | grep "NDISSTATQRY: 0,"; then
	echo "Modem $2 : DISCONNECTED"
	echo -e "AT^NDISDUP=1,0\r" | microcom -t 1000 /dev/$PORT
	CONNECTED=""
	fi
fi


done

