#!/usr/bin/env bash -ex

# Based on a blog found on https://www.hostafrica.com/blog/kubernetes/kubernetes-cluster-centos-stream-containerd/
# ??? See also the official documentation on https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#   --> chapter: containerd
#   --> Tab: ???

#
# Prerequisites
#

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl -a -–system

#
# Install Containerd
#

# Add the official Docker repository
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo

# Update your system and install the containerd package
sudo dnf update
sudo dnf install -y containerd

# Create a configuration file for containerd and set it to defaulti, but set SystemdCgroup to true (required by kubelet)
sudo mkdir -p /etc/containerd
sudo containerd config default | sed 's/SystemdCgroup = false/SystemdCgroup = true/g' | sudo tee /etc/containerd/config.toml



sudo systemctl enable containerd
sudo systemctl restart containerd
sudo systemctl status containerd

ps -ef | grep containerd

