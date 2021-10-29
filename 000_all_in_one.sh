#!/usr/bin/env bash

# Stop on Error
set -e

NUMBER_OF_VOLUMES=${NUMBER_OF_VOLUMES:=100}

# Role Detection by hostname
hostname | grep master || AGENT=true
hostname | grep node || MASTER=true

echo "MASTER=${MASTER}"
echo "AGENT=${AGENT}"

if [ "${MASTER}" == "true" ]; then

  # TODO: to get rid of the user input: test another possibility:
  #  can we just use the hostname without DOMAIN? I guess, not, if we do not want to add the IP-Address to /etc/hosts?
  #  export API_NAME=${API_NAME:=$(hostname)}
  #  export CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:=$(hostname)}

  # Ask user for CONTROL_PLANE_ENDPOINT value:
  export CONTROL_PLANE_ENDPOINT=${CONTROL_PLANE_ENDPOINT:=$(hostname).vocon-it.com}
  read -e -i "${CONTROL_PLANE_ENDPOINT}" -p "CONTROL_PLANE_ENDPOINT=" CONTROL_PLANE_ENDPOINT

  # Ask user for API_NAME value:
  # TODO: API_NAME does not seem to be used anywhere? Clean it, if you do not use it.
  export API_NAME="${CONTROL_PLANE_ENDPOINT:=master1.prod.vocon-it.com}"
  read -e -i "${API_NAME}" -p "API_NAME=" API_NAME

  if [ "${DEBUG}" == "true" ]; then
    echo CONTROL_PLANE_ENDPOINT=$CONTROL_PLANE_ENDPOINT
    echo API_NAME=$API_NAME
  fi

fi

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
if [ "${MASTER}" == "true" ]; then
  bash 2_install_kubeadm/4_deploy_overlay_network.sh || false
else
  echo "The node is no master. Skipping this step."
fi

echo "----------------------"
echo "--- UNTAINT MASTER ---"
echo "----------------------"
echo
if [ "${MASTER}" == "true" ] && [ "${AGENT}" == "true" ]; then
  bash 2_install_kubeadm/5_untaint_master.sh || false
else
  echo "The node is no master and agent. Skipping this step."
fi

echo "--------------------------------------"
echo "--- ADD EXTERNAL VOLUME IF NEEDED  ---"
echo "--------------------------------------"
echo
[ "${AGENT}" == "true" ] \
  && echo "If needed: on Hetzner Cloud, add an XFS Vomume to the agent machine and perform the steps found on 'Show Configuration':" \
  && echo 'Example:' \
  && echo '   sudo mkfs.xfs -f  /dev/disk/by-id/scsi-0HC_Volume_8726516t' \
  && echo '   sudo mkdir /mnt/prod-node-volume-nbg1-1-xfs' \
  && echo '   sudo mount -o discard,defaults /dev/disk/by-id/scsi-0HC_Volume_8726516 /mnt/prod-node-volume-nbg1-1-xfs' \
  && echo '   echo "/dev/disk/by-id/scsi-0HC_Volume_8726516 /mnt/prod-node-volume-nbg1-1-xfs xfs discard,nofail,defaults 0 0" | sudo tee -a /etc/fstab' \
  && echo "Note the sudo commands and the sudo tee -a in the last command" \
  && echo "Perform the adapted commands in a separate window. Press any key, when you are done..." \
  && while true; do echo -n .; read -s -t 10 -a REPLY && break; done || true; echo

echo "----------------------------------------------"
echo "--- ADD KUBE PERSISTENT VOLUMES IF NEEDED  ---"
echo "----------------------------------------------"
echo
if [ "${AGENT}" == "true" ]; then
  sudo bash 4_create_persistent_volumes/1_storage_class.sh \
    && sudo bash 4_create_persistent_volumes/3_add_local_volumes.sh
else
  true
fi

echo "----------------------------"
echo "--- INSTALL CERT-MANAGER ---"
echo "----------------------------"
echo
if [ "${MASTER}" == "true" ] && [ "${AGENT}" == "true" ]; then
  bash 7_install_cert_manager/1_install_cert-manager.sh
else
  echo "The node is no master and agent. Skipping this step."
fi

echo "--------------------------------------"
echo "--- ADD KUBE ALIASES AND FUNCTIONS ---"
echo "--------------------------------------"
echo
bash 8_kube_aliases_and_autocompletion.sh

echo "--------------------------------------"
echo "--- MANUAL STEP: Join master      ---"
echo "--------------------------------------"
echo

[ "${MASTER}" != "true" ] && [ "${AGENT}" == "true" ] \
  && echo "Copy the kubeadm join command from the master:/tmp/kubeinit.log to the agent." \
  && echo "You might have to add the master IP address to /etc/hosts for this to succeed." \
  && echo "Perform this in a separate window. Press any key, when you are done..." \
  && while true; do echo -n .; read -s -t 10 -a REPLY && break; done || true; echo


echo "--------------------------------------"
echo "--- MANUAL STEP: Copy .kube/config ---"
echo "--------------------------------------"
echo

[ "${MASTER}" != "true" ] && [ "${AGENT}" == "true" ] \
  && echo "Please copy centos@master1:.kube/config to the agent." \
  && echo "Try:" \
  && echo "$ scp centos@master1:.kube/config ~/.kube/" \
  && echo "replace master1 to a reachable domain name or IP address of a master (e.g. master.prod.vocon-it.com)" \
  && echo "Perform this in a separate window. Press any key, when you are done..." \
  && while true; do echo -n .; read -s -t 10 -a REPLY && break; done || true; echo


echo "--------------------------------------"
echo "--- FINISHED INSTALLING KUBERNETES ---"
echo "--------------------------------------"
echo





# TODO: add other scripts


