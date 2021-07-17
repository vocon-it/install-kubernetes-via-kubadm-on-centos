
sudo yum remove -y kubelet kubeadm kubctl
DOCKER_OLD=$(sudo yum list installed | grep docker | awk '{print $1}')
[ "${DOCKER_OLD}" != "" ] && sudo yum remove -y "${DOCKER_OLD}"