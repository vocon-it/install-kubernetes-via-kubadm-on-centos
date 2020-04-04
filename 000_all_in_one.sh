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
bash 2_install_kubeadm/2_reset_kubeadm.sh

# INIT KUBEADM
bash 2_install_kubeadm/3_initialize_kubeadm.sh

# DEPLOY OVERLAY NETWORK
bash 2_install_kubeadm/4_deploy_overlay_network.sh

# UNTAINT MASTER
bash 2_install_kubeadm/5_untaint_master.sh

# CREATE PERSISTENT VOLUMES
bash 4_create_persistent_volumes/1_storage_class.sh
NUMBER_OF_VOLUMES=100 \
bash 4_create_persistent_volumes/3_add_local_volumes.sh 

# TODO: add other scripts


