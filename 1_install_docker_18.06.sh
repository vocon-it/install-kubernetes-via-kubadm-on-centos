
docker --version \
  && echo "INFO: docker is already installed. Skipping this step..." \
  && exit 0

# install docker
yum check-update

# install latest docker: skipped in favor of the installation of v18.06 below
#curl -fsSL https://get.docker.com/ | sh

# install docker v 18.06, which is compatible with latest kubectl 
sudo echo nothing 2>/dev/null 1>/dev/null || alias sudo='$@'

sudo tee /etc/yum.repos.d/docker.repo <<-'EOF' 
[docker-ce-edge]
name=Docker CE Edge - $basearch
baseurl=https://download.docker.com/linux/centos/7/$basearch/edge
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

sudo yum install -y docker-ce-18.06.1.ce-3.el7.x86_64 

# allow sudo rights of docker service:
sudo usermod -aG docker $(whoami)

# start docker now:
sudo systemctl start docker
sudo systemctl status docker

# start docker automatically after boot:
sudo systemctl enable docker

echo 'Docker should be installed now. Try with "sudo docker search hello".'
echo 'After logout and login again, "sudo" will not be needed anymore'
