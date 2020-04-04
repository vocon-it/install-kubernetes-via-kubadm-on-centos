#!/usr/bin/env bash

sudo kubeadm init --kubernetes-version $(kubeadm version -o short) --pod-network-cidr=10.244.0.0/16 --dry-run \
  && sudo kubeadm init --kubernetes-version $(kubeadm version -o short) --pod-network-cidr=10.244.0.0/16 \
     | sudo tee /tmp/kubeinit.log \
  && echo "Note: the full initialization log can be found on /tmp/kubeinit.log" \
  && mkdir -p $HOME/.kube \
  && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config \
  && sudo chown $(id -u):$(id -g) $HOME/.kube/config \
  && sudo mkdir -p /root/.kube \
  && sudo cp /etc/kubernetes/admin.conf /root/.kube/config

[ "$?" != 0 ] && echo "ERROR: operation failed. If kubeadm is initialized already and you want to re-initialize, try option --reset" && false
