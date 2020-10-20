
# install docker

# Exit on Error
set -e

sudo echo nothing 2>/dev/null 1>/dev/null || alias sudo='$@'

yum check-update

# install docker v 18.06, which is compatible with latest kubectl 

echo "--- Add the Docker repository ---"
sudo tee /etc/yum.repos.d/docker.repo <<-'EOF' || [ "$?" == "100" ]
[docker-ce-edge]
name=Docker CE Edge - $basearch
baseurl=https://download.docker.com/linux/centos/7/$basearch/edge
enabled=1
gpgcheck=1
gpgkey=https://download.docker.com/linux/centos/gpg
EOF

 #  echo "\$?=$?"

echo "--- Install Docker CE ---"
sudo yum install -y docker-ce-18.06.1.ce-3.el7.x86_64

 # echo "\$?=$?"   

echo "--- Allow sudo rights of docker service ---"
sudo usermod -aG docker $(whoami)

 # echo "\$?=$?"   

echo "--- Start docker now ---"
sudo systemctl start docker
sudo systemctl status docker

 # echo "\$?=$?"   

echo "--- Start docker automatically after boot ---"
sudo systemctl enable docker

 # echo "\$?=$?"   

echo 'Docker should be installed now. Try with "sudo docker search hello".'
echo 'After logout and login again, "sudo" will not be needed anymore'

echo "--- Print installed Docker Version ---"
sudo docker --version

 # echo "\$?=$?"   
