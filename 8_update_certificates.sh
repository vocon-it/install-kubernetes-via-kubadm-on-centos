#!/usr/bin/env bash

# from https://stackoverflow.com/a/56334732/1147487:

# TODO: create story for distributing .kube configs to all kube clients
# TODO: run this as non-root using sudo
#[ "$(id -u)" != "0" ] && echo "$0 must be run as root. Exiting..." && exit 1

sudo echo test 2>/dev/null 1>/dev/null || alias sudo='$@'
DATETIME=$(date '+%Y-%m-%d--%H-%M-%S')

# Detect own IP address and check that it is a correct IPv4 address:
API_IP=$(sudo /sbin/ifconfig eth0 | grep -v inet6 | grep inet | awk '{print $2}') \
  && echo "$API_IP" | egrep -v "^[1-9][0-9]{0,2}\.[1-9][0-9]{0,2}.[1-9][0-9]{0,2}.[1-9][0-9]{0,2}$" \
  && echo "ERROR: could not find IP address. Exiting ..." && exit 1

# Move the old folder contents out of the way (otherwise the next step will fail):
sudo mv /etc/kubernetes/pki /etc/kubernetes/pki.bak-${DATETIME}

# Create new Certificates:
sudo kubeadm init phase certs all --apiserver-advertise-address $API_IP

# Create Backup of the old configurations:
sudo mkdir -p /root/kubernetes-pki.bak-${DATETIME} \
  && sudo mv /etc/kubernetes/{admin.conf,controller-manager.conf,kubelet.conf,scheduler.conf} /root/kubernetes-pki.bak-${DATETIME}/

# Create new configuration files:
sudo kubeadm init phase kubeconfig all \
  && mkdir -p $HOME/.kube \
  && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config \
  && sudo chown $(id -u):$(id -g) $HOME/.kube/config \
  && sudo mkdir -p /root/.kube \
  && sudo cp /etc/kubernetes/admin.conf /root/.kube/config


# reboot needed:
ANSWER=no
read -p "A reboot is needed. Rebooting now? (yes|no) > " ANSWER
[ "$(echo $ANSWER | cut -c 1 | awk '{print tolower($0)}')" == "y" ] && sudo reboot
