#!/usr/bin/env bash

# If you eant .kube to be created for a non-root user, then run this script as the non-root user:

#APISERVER_ADVERTISE_ADDRESS=${APISERVER_ADVERTISE_ADDRESS:=$(hostname)}
#  --apiserver-advertise-address=${APISERVER_ADVERTISE_ADDRESS} \

CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:=$(hostname -f)}

# prerequisite: switch on routing
cat /proc/sys/net/ipv4/ip_forward | grep 1 || echo "1" | sudo tee cat /proc/sys/net/ipv4/ip_forward

sudo kubeadm init \
  --kubernetes-version $(kubeadm version -o short) \
  --pod-network-cidr=10.244.0.0/16 \
  --control-plane-endpoint=${CONTROL_PLANE_ENDPOINT} \
  --ignore-preflight-errors=NumCPU \
  --dry-run \
  && sudo kubeadm init \
    --kubernetes-version $(kubeadm version -o short) \
    --pod-network-cidr=10.244.0.0/16 \
    --control-plane-endpoint=${CONTROL_PLANE_ENDPOINT} \
    --ignore-preflight-errors=NumCPU \
     | sudo tee /tmp/kubeinit.log \
  && echo "Note: the full initialization log can be found on /tmp/kubeinit.log" \
  && mkdir -p $HOME/.kube \
  && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config \
  && sudo chown $(id -u):$(id -g) $HOME/.kube/config \
  && sudo mkdir -p /root/.kube \
  && sudo cp /etc/kubernetes/admin.conf /root/.kube/config

if [ "$?" != 0 ]; then
  echo "ERROR: operation failed. If kubeadm is initialized already and you want to re-initialize, try option --reset"
  false
else
  true
fi
