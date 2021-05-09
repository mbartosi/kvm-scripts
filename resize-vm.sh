#!/bin/bash

vm_name=kube01

lvrename /dev/vg0raid/$vm_name /dev/vg0raid/$vm_name.bak
lvcreate -L 30G -n $vm_name /dev/vg0raid
virt-resize /dev/vg0raid/$vm_name.bak /dev/vg0raid/$vm_name --expand /dev/sda2
lvremove /dev/vg0raid/$vm_name.bak
