#!/bin/bash

if1=`cat /etc/netplan/50-cloud-init.yaml  | grep set-name: | awk '{print $NF}' | head -1`
if2=`cat /etc/netplan/50-cloud-init.yaml  | grep set-name: | awk '{print $NF}' | tail -1`
if1_addr=`/bin/ip addr show dev ${if1} | grep -oP '(?<=inet\s)(.*)(?=/)'`
if1_mask=`ip addr show dev ${if1} | grep -oP '(?<=\d\/)(.*)(?=\sbrd\s)'`
if2_addr=`ip addr show dev ${if2} | grep -oP '(?<=inet\s)(.*)(?=/)'`
if2_mask=`ip addr show dev ${if2} | grep -oP '(?<=\d\/)(.*)(?=\sbrd\s)'`
gw=`ip route | grep -oP '(?<=default\svia\s)(.*)(?=\sdev)'`

cat << EOF > /etc/netplan/50-cloud-init.yaml
network:
    version: 2
    ethernets:
        eth0:
            addresses: [${if1_addr}/${if1_mask}]
            gateway4: ${gw}
            nameservers:
                addresses: [1.1.1.1, 8.8.8.8, 8.8.4.4]
            dhcp4: no
            mtu: 1450
        eth1:
            addresses: [${if2_addr}/${if2_mask}]
            routes: []
            dhcp4: no
            mtu: 1450
EOF