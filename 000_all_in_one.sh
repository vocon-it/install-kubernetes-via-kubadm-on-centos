#!/usr/bin/env bash

# Stop on Error
set -e

# Roles
hostname | grep master && MASTER=true || true
hostname | grep node && AGENT=true || true
[ "${MASTER}" == "" ] && [ "${AGENT}" == "" ]  && MASTER=true && AGENT=true || true

echo "MASTER=${MASTER}"
echo "AGENT=${AGENT}"

# Define sudo, if it does not yet exist:
sudo echo nothing 2>/dev/null 1>/dev/null || alias sudo='$@'

echo "---------------------------------"
echo "--- INSTALL DOCKER, IF NEEDED ---"
echo "---------------------------------"
echo
sudo docker --version \
  && echo "INFO: docker is already installed. Skipping this step..." \
  || bash 1_install_docker.sh

echo "----------------------------------"
echo "--- INSTALL KUBEADM, IF NEEDED ---"
echo "----------------------------------"
echo
kubeadm version -o short \
  && echo "INFO: kubeadm is already installed. Skipping this step..." \
  || bash 2_install_kubeadm/1_install_kubeadm.sh

echo "---------------------"
echo "--- RESET KUBEADM ---"
echo "---------------------"
echo
bash 2_install_kubeadm/2_reset_kubeadm.sh || false

echo "--------------------"
echo "--- INIT KUBEADM ---"
echo "--------------------"
echo
if [ "${MASTER}" == "true" ]; then
  bash 2_install_kubeadm/3_initialize_kubeadm.sh || false
else
  echo "The node is no master. Skipping this step."
fi

echo "------------------------------"
echo "--- DEPLOY OVERLAY NETWORK ---"
echo "------------------------------"
echo
bash 2_install_kubeadm/4_deploy_overlay_network.sh || false

echo "----------------------"
echo "--- UNTAINT MASTER ---"
echo "----------------------"
echo
if [ "${MASTER}" == "true" ] && [ "${AGENT}" == "true" ]; then
  bash 2_install_kubeadm/5_untaint_master.sh || false
else
  echo "The node is no master and agent. Skipping this step."
fi


# CREATE PERSISTENT VOLUMES 
# ----- SWITCHED OFF -----
#bash 4_create_persistent_volumes/1_storage_class.sh
#NUMBER_OF_VOLUMES=100 \
#bash 4_create_persistent_volumes/3_add_local_volumes.sh 

echo "--------------------------------------"
echo "--- ADD KUBE ALIASES AND FUNCTIONS ---"
echo "--------------------------------------"
echo
bash 8_kube_aliases_and_autocompletion.sh

echo "--------------------------------------"
echo "--- FINISHED INSTALLING KUBERNETES ---"
echo "--------------------------------------"
echo
# TODO: add other scripts


