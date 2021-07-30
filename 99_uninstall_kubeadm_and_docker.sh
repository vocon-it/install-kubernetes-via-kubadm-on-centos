#!/usr/bin/env bash -ex

DATETIME=$(date +"%Y-%m-%d--%H-%M-%S")
mv ~/.kube/config ~/.kube/config-${DATETIME} || true
sudo mv /root/.kube/config /root/.kube/config-${DATETIME} || true

sudo yum list installed | egrep "docker|kubelet|kubeadm|kubectl" | awk '{print $1}'

OLD_PACKAGES=$(sudo yum list installed | egrep "docker|kubelet|kubeadm|kubectl" | awk '{print $1}')
for PACKAGE in ${OLD_PACKAGES}; do
  echo "PACKAGE=${PACKAGE}"
  sudo yum remove -y "${PACKAGE}" && echo removed package ${PACKAGE}
done

