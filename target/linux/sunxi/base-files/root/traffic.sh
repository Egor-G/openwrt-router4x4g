#!/bin/sh

tc qdisc add dev eth0 root handle 1: htb
tc class add dev eth0 parent 1: classid 1:1 htb rate 50Mbit
for I in `seq 100 150`
do
	tc class add dev eth0 parent 1:1 classid 1:1$I htb rate 1Mbit ceil 2Mbit prio 1
	tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 match ip dst 192.168.2.$I flowid 1:1$I
done

