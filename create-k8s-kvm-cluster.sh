#!/bin/bash

# ==== Config section:
# Template VM name (must exist):
source_vm=debian11

# New VM names, first one is the master node:
vm_names=( kube-master kube1 )
# New disk size for all nodes:
vm_size=30
# New memory size for all nodes:
vm_memory=4096

# ==== Script:

function connect_ssh () {
    echo Running $3 script on $2:
    ssh -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$1"@"$2" < "$3"
}

function wait_ssh () {
    echo Trying SSH connection to host: $1...
    # wait for host up:
    until nc -vzw 2 $1 22 > /dev/null 2>&1; do sleep 2; done
    echo SSH server $1 up.
}

# Clone and sysprep loop:
for vm in "${vm_names[@]}"
do
    echo Cloning from: $source_vm VM to new: $vm VM
    virt-clone --original $source_vm --name $vm --file /dev/vg0raid/$vm
    echo Preparing: $vm
    virt-sysprep --network --enable dhcp-client-state,dhcp-server-state,machine-id,ssh-hostkeys,customize --firstboot-command "dpkg-reconfigure openssh-server" --install kubelet,kubeadm,kubectl --hostname $vm -d $vm
done

# Resize loop. Only resize if VM size is >20GB (source =20GB now).
if [ $vm_size -gt 20 ]
then
    for vm in "${vm_names[@]}"
        do
        echo Resising VM $vm disk to $vm_size GB...
        lvrename /dev/vg0raid/$vm /dev/vg0raid/$vm.old
        lvcreate --size $vm_size /dev/vg0raid/$vm
        virt-resize --expand /dev/sda2 /dev/vg0raid/$vm.old /dev/vg0raid/$vm
    done
fi

# Set memory size loop:
for vm in "${vm_names[@]}"
do
    echo Setting new memory size for $vm: "$vm_memory"M
    virsh setmaxmem $vm "$vm_memory"M --config
    virsh setmem $vm "$vm_memory"M --config
done

# Bring up all VMs:
for vm in "${vm_names[@]}"
do
    echo Starting $vm...
    virsh start $vm
done

for vm in "${vm_names[@]}"
do
    wait_ssh $vm
done

# Kubernetes part here:
# Create master (vm_names[0] is the master VM):
ssh -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@${vm_names[0]} < create-kubeadm-cluster.sh

token=$(ssh -q -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o LogLevel=error root@${vm_names[0]} < get-token.sh | tail -n 1)
hash=$(ssh -q -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o LogLevel=error root@${vm_names[0]} < get-hash.sh | tail -n 1)
master_ip=$(ssh -q -o BatchMode=yes -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no -o LogLevel=error root@${vm_names[0]} < get-ip.sh | tail -n 1)

echo Detected Kubernetes info from master node ${vm_names[0]}:
echo IP: $master_ip
echo Token: $token
echo Hash: $hash

# Join workers:
cat << EOF > join-kubeadm-cluster.sh
#/bin/bash
kubeadm join $master_ip:6443 --token $token --discovery-token-ca-cert-hash sha256:$hash
EOF

chmod +x join-kubeadm-cluster.sh

for vm in "${vm_names[@]:1}"
do
    echo Joining $vm to ${vm_names[0]}:
    ssh -o CheckHostIP=no -o ConnectTimeout=10 -o StrictHostKeyChecking=no root@$vm < join-kubeadm-cluster.sh
done

rm join-kubeadm-cluster.sh
