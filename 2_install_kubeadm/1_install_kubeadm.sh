
KUBELET_VERSION=${KUBELET_VERSION:=kubelet-1.18.2-0.x86_64}
KUBEADM_VERSION=${KUBEADM_VERSION:=kubeadm-1.18.2-0.x86_64}
KUBECTL_VERSION=${KUBECTL_VERSION:=kubectl-1.18.2-0.x86_64}

if kubeadm version -o short; then
  echo "INFO: kubeadm is already installed. Skipping this step..." \
else
  [ -r /etc/yum.repos.d/kubernetes.repo ] || cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF
  
  # Set SELinux in permissive mode (effectively disabling it)
  sudo setenforce 0
  sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
  
  sudo yum install -y ${KUBELET_VERSION} ${KUBEADM_VERSION} ${KUBECTL_VERSION} --disableexcludes=kubernetes
  
  sudo systemctl enable kubelet \
    && sudo systemctl start kubelet
  
  kubeadm version -o short
  
  # In addition, we need to perform following commands in order to avoid issues some users have reported: there, the iptables were bypassed.
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
  
  sudo sysctl --system
fi
