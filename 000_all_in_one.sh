#!/usr/bin/env bash

# INSTALL DOCKER IF NEEDED
BOOTSTRAP_BRANCH=dev2-2-disable-web-access
docker --version || \
  curl https://raw.githubusercontent.com/oveits/bootstrap-centos/${BOOTSTRAP_BRANCH}/4_install_docker.sh \
  | bash -

# INSTALL KUBEADM IF NEEDED
kubeadm version -o short || \
  bash 2_install_kubeadm/1_install_kubeadm.sh

# RESET KUBEADM
bash 2_install_kubeadm/2_initialize_kubeadm.sh --reset


