#!/usr/bin/env bash

# Stop on Error
set -e

# Define sudo, if it does not yet exist:
sudo echo nothing 2>/dev/null 1>/dev/null || alias sudo='$@'

echo "--- INSTALL DOCKER, IF NEEDED ---"
sudo docker --version \
  && echo "INFO: docker is already installed. Skipping this step..." \
  || source 1_install_docker_18.06.sh

echo "--- INSTALL KUBEADM, IF NEEDED ---"
kubeadm version -o short \
  && echo "INFO: kubeadm is already installed. Skipping this step..." \
  || bash 2_install_kubeadm/2_install_kubeadm.sh

echo "--- RESET KUBEADM ---"
bash 2_install_kubeadm/2_reset_kubeadm.sh || false

echo "--- INIT KUBEADM ---"
bash 2_install_kubeadm/3_initialize_kubeadm.sh || false

exit 0

echo "--- DEPLOY OVERLAY NETWORK ---"
bash 2_install_kubeadm/4_deploy_overlay_network.sh || false

echo "--- UNTAINT MASTER ---"
bash 2_install_kubeadm/5_untaint_master.sh || false

# CREATE PERSISTENT VOLUMES 
# ----- SWITCHED OFF -----
#bash 4_create_persistent_volumes/1_storage_class.sh
#NUMBER_OF_VOLUMES=100 \
#bash 4_create_persistent_volumes/3_add_local_volumes.sh 

echo "--- ADD KUBE ALIASES AND FUNCTIONS ---"
bash 8_kube_aliases_and_autocompletion.sh


# TODO: add other scripts


