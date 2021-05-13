#!/bin/bash
interface=$(ls /sys/class/net | grep ^e)
address=$(ip -o -4 addr list $interface | awk '{print $4}' | cut -d/ -f1)
echo $address
