cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
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

KUBERNETES_VERISON=1.18.2-0.x86_64

sudo yum install -y kubelet-${KUBERNETES_VERISON} kubeadm-${KUBERNETES_VERISON} kubectl-${KUBERNETES_VERISON} --disableexcludes=kubernetes

sudo systemctl enable kubelet \
  && sudo systemctl start kubelet

kubeadm version -o short

# In addition, we need to perform following commands in order to avoid issues some users have reported: there, the iptables were bypassed.
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sudo sysctl --system
