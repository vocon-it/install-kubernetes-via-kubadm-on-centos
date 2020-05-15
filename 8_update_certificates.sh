#!/usr/bin/env bash

# from https://stackoverflow.com/a/56334732/1147487:

# TODO: create story for distributing .kube configs to all kube clients
# TODO: run this as non-root using sudo
[ "$(id -u)" != "0" ] && echo "$0 must be run as root. Exiting..." && exit 1

# Detect own IP address and check that it is a correct IPv4 address:
API_IP=$(/sbin/ifconfig eth0 | grep -v inet6 | grep inet | awk '{print $2}') \
  && echo "$API_IP" | egrep -v "^[1-9][0-9]{0,2}\.[1-9][0-9]{0,2}.[1-9][0-9]{0,2}.[1-9][0-9]{0,2}$" \
  && echo "ERROR: could not find IP address. Exiting ..." && exit 1

# Create backup of the Certificates:
cd /etc/kubernetes/pki/ \
  && mkdir -p ~/kubernetes-pki.bak \
  && mv {apiserver.crt,apiserver-etcd-client.key,apiserver-kubelet-client.crt,front-proxy-ca.crt,front-proxy-client.crt,front-proxy-client.key,front-proxy-ca.key,apiserver-kubelet-client.key,apiserver.key,apiserver-etcd-client.crt} ~/kubernetes-pki.bak/ \

# Create new Certificates:
kubeadm init phase certs all --apiserver-advertise-address $API_IP

# Create Backup of the old configurations:
cd /etc/kubernetes/ \
  && mv {admin.conf,controller-manager.conf,kubelet.conf,scheduler.conf} ~/kubernetes-pki.bak/

# Create new configuration files:
kubeadm init phase kubeconfig all \
  && mkdir -p $HOME/.kube \
  && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config \
  && sudo chown $(id -u):$(id -g) $HOME/.kube/config
#  && sudo mkdir -p /root/.kube \
#  && sudo cp /etc/kubernetes/admin.conf /root/.kube/config


# reboot needed:
reboot
