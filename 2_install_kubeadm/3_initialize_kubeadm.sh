#!/usr/bin/env bash

# If you want .kube to be created for a non-root user, then run this script as the non-root user:

DOMAIN=${DOMAIN:=vocon-it.com}

[ "$(hostname)" == "$(hostname -f)" ] && echo please spedify the fully qualified domain name in /etc/hosts first && exit 1
CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:=$(hostname -f)}

# not needed?
#APISERVER_ADVERTISE_ADDRESS=${APISERVER_ADVERTISE_ADDRESS:=$(hostname -f)}}
#  --apiserver-advertise-address=${APISERVER_ADVERTISE_ADDRESS} \

# prerequisite: switch on routing
#cat /proc/sys/net/ipv4/ip_forward | grep 1 || echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward
cat /proc/sys/net/ipv4/ip_forward | grep 1 || sudo sysctl -w net.ipv4.ip_forward=1
#cat /proc/sys/net/ipv6/conf/all/forwarding | grep 1 || echo "1" | sudo tee /proc/sys/net/ipv6/conf/all/forwarding
cat /proc/sys/net/ipv6/conf/all/forwarding | grep 1 || sudo sysctl -w net.ipv6.conf.all.forwarding=1

sudo kubeadm init \
  --kubernetes-version $(kubeadm version -o short) \
  --control-plane-endpoint=${CONTROL_PLANE_ENDPOINT} \
  --ignore-preflight-errors=NumCPU \
  --pod-network-cidr=10.244.0.0/16,2001:db8:42:0::/56 \
  --service-cidr=10.96.0.0/16,2001:db8:42:1::/112 \
  --dry-run \
  && sudo kubeadm init \
    --kubernetes-version $(kubeadm version -o short) \
    --control-plane-endpoint=${CONTROL_PLANE_ENDPOINT} \
    --ignore-preflight-errors=NumCPU \
    --pod-network-cidr=10.244.0.0/16,2001:db8:42:0::/56 \
    --service-cidr=10.96.0.0/16,2001:db8:42:1::/112 \
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
