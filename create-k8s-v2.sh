#!/bin/bash

source_vm=debian11
vm_names=( km k1 )

function connect_ssh () {
    echo Running $3 script on $2:
    ssh -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$1"@"$2" < "$3"
}

function wait_ssh () {
    echo Trying SSH connection to $2...
    # wait for host up:
    until nc -vzw 2 $1 22 > /dev/null 2>&1; do sleep 2; done
    # try ssh connection:
#    ssh -o BatchMode=yes -o CheckHostIP=no -o ConnectionAttempts=30 -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$1"@"$2" exit
#    if [ $? != "0" ]; then
#        echo Connection to $2 failed
#    fi
    echo SSH server $1 up.
}

#for vm in "${vm_names[@]}"
#do
#    echo Cloning from: $source_vm VM to new: $vm VM
#    virt-clone --original $source_vm --name $vm --file /dev/vg0raid/$vm
#    echo Preparing: $vm
#    virt-sysprep --network --enable dhcp-client-state,dhcp-server-state,machine-id,ssh-hostkeys,customize --firstboot-command "dpkg-reconfigure openssh-server" --install kubelet,kubeadm,kubectl --hostname $vm -d $vm
#done

for vm in "${vm_names[@]}"
do
    echo Starting $vm...
    virsh start $vm
done

wait_ssh km
token=$(ssh -q -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o LogLevel=error root@km < get-token.sh | tail -n 1)
hash=$(ssh -q -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o LogLevel=error root@km < get-hash.sh | tail -n 1)

echo Token: $token
echo Hash: $hash
