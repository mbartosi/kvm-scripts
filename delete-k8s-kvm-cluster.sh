#!/bin/bash

vm_names=( kube-master kube1 kube2 kube3 )

for vm in "${vm_names[@]}"
do
    echo Destroying VM: $vm
    virsh destroy $vm
    echo Deleting VM and storage: $vm
    virsh undefine $vm --remove-all-storage --nvram
done
