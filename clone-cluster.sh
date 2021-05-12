#!/bin/bash

source_vm=debian11
vm_names=( kube-master kube01 kube02 )

for vm in "${vm_names[@]}"
do
    echo Cloning from: $source_vm VM to new: $vm VM
    virt-clone --original $source_vm --name $vm --file /dev/vg0raid/$vm
    sync
    echo Preparing: $vm
    virt-sysprep --enable dhcp-client-state,dhcp-server-state,machine-id,ssh-hostkeys,customize --firstboot-command "dpkg-reconfigure openssh-server" --hostname $vm -d $vm
done
