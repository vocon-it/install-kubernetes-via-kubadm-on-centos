
# Based on the official documentation (2020-10-20) on https://kubernetes.io/docs/setup/production-environment/container-runtimes/
#   --> chapter: Docker
#   --> Tab: CentOS/RHEL 7.4+

# +The + sign on the comment mark deviations/additions from the official documentation

# +Versions
CONTAINERD_VERSION=${CONTAINERD_VERSION:=1.2.13}
DOCKER_VERSION=${DOCKER_VERSION:=19.03.11}


# +Update
sudo yum check-update

# (Install Docker CE)
## Set up the repository
### Install required packages
sudo yum install -y yum-utils device-mapper-persistent-data lvm2

## Add the Docker repository
sudo yum-config-manager --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

## Install Docker CE
sudo yum update -y && sudo yum install -y \
  containerd.io-${CONTAINERD_VERSION} \
  docker-ce-${DOCKER_VERSION} \
  docker-ce-cli-${DOCKER_VERSION}

## Create /etc/docker
sudo mkdir /etc/docker

# Set up the Docker daemon
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF

sudo mkdir -p /etc/systemd/system/docker.service.d

# allow sudo rights of docker service:
sudo usermod -aG docker $(whoami)

# Start docker now:
sudo systemctl start docker
sudo systemctl status docker

# Start docker automatically after boot:
sudo systemctl enable docker

echo 'Docker should be installed now. Try with "sudo docker search hello".'
echo 'After logout and login again, "sudo" will not be needed anymore'

sudo docker --version
