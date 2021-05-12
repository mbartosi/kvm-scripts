#!/bin/bash

source_vm=debian11
vm_names=( kube-master kube01 kube02 )

for vm in "${vm_names[@]}"
do
    echo Cloning from: $source_vm VM to new: $vm VM
    virt-clone --original $source_vm --name $vm --file /dev/vg0raid/$vm
    echo Preparing: $vm
    virt-sysprep --network --enable dhcp-client-state,dhcp-server-state,machine-id,ssh-hostkeys,customize --firstboot-command "dpkg-reconfigure openssh-server" --install kubelet,kubeadm,kubectl --hostname $vm -d $vm
done

for vm in "${vm_names[@]}"
do
    echo Starting $vm...
    virsh start $vm
done
