
# Official documentation: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-kubeadm-kubelet-and-kubectl
# --> Tab: CentOS, RHEL or Fedora
# This file reflects the status of 2020-10-20 (v1.19.3)

# Exit on Error
set -e

sudo yum list installed | grep kubeadm && echo "kubeadm is already installed. You need do remove kubeadm first." && false

# latest tested version (dev-node2):
KUBEADM_VERSION=${KUBEADM_VERSION:=1.20.3}
if [ "${KUBEADM_VERSION}" != "" ]; then
  KUBELET_PACKAGE=${KUBELET_PACKAGE:=kubelet-${KUBEADM_VERSION}-0.x86_64}
  KUBEADM_PACKAGE=${KUBEADM_PACKAGE:=kubeadm-${KUBEADM_VERSION}-0.x86_64}
  KUBECTL_PACKAGE=${KUBECTL_PACKAGE:=kubectl-${KUBEADM_VERSION}-0.x86_64}
else
  # install latest:
  KUBELET_PACKAGE=${KUBELET_PACKAGE:=kubelet}
  KUBEADM_PACKAGE=${KUBEADM_PACKAGE:=kubeadm}
  KUBECTL_PACKAGE=${KUBECTL_PACKAGE:=kubectl}
fi

echo "Installing ${KUBELET_PACKAGE}, ${KUBEADM_PACKAGE} and ${KUBECTL_PACKAGE}"

echo "--- Letting iptables see bridged traffic ---"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

echo "--- Adding Kube Repo ---"
[ -r /etc/yum.repos.d/kubernetes.repo ] || cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF
  
# Set SELinux in permissive mode (effectively disabling it)
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y ${KUBELET_PACKAGE} ${KUBEADM_PACKAGE} ${KUBECTL_PACKAGE} --disableexcludes=kubernetes

sudo systemctl enable --now kubelet

kubeadm version -o short

