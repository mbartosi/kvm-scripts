#!/bin/bash
kubeadm token list | awk 'NR == 2 {print $1}'
