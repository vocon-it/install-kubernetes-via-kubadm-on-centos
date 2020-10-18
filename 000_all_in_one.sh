#!/usr/bin/env bash

set -euxo pipefail

# INSTALL DOCKER IF NEEDED
BOOTSTRAP_BRANCH=dev2-2-disable-web-access
docker --version || \
  curl https://raw.githubusercontent.com/oveits/bootstrap-centos/${BOOTSTRAP_BRANCH}/4_install_docker.sh \
  | bash -

# INSTALL KUBEADM IF NEEDED
kubeadm version -o short || \
  bash 2_install_kubeadm/1_install_kubeadm.sh

# RESET KUBEADM
bash 2_install_kubeadm/2_reset_kubeadm.sh || false

# INIT KUBEADM
bash 2_install_kubeadm/3_initialize_kubeadm.sh || false

# DEPLOY OVERLAY NETWORK
bash 2_install_kubeadm/4_deploy_overlay_network.sh || false

# UNTAINT MASTER
bash 2_install_kubeadm/5_untaint_master.sh || false

# CREATE PERSISTENT VOLUMES 
# ----- SWITCHED OFF -----
#bash 4_create_persistent_volumes/1_storage_class.sh
#NUMBER_OF_VOLUMES=100 \
#bash 4_create_persistent_volumes/3_add_local_volumes.sh 

# KUBE ALIASES AND FUNCTIONS
bash 8_kube_aliases_and_autocompletion.sh


# TODO: add other scripts


