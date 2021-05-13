#!/bin/bash
interface=$(ls /sys/class/net | grep ^e)
address=$(ip -o -4 addr list $interface | awk '{print $4}' | cut -d/ -f1)
echo $interface > int_name
echo $address > int_address
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$address
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
