
# reset kubeadm and firewall rules, if it was already initialized:
if [ "$1" == "--reset" ]; then
  answer=yes
  read -t 10 -p "This will reset kubeadm and all firewall rules. Continue? ($answer) > " a
  if [ "$answer" == "y" -o "$answer" == "yes" ]; then
    sudo kubeadm reset && sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X && bash 3_create_iptables_entries.sh
  fi
fi

sudo kubeadm init --kubernetes-version $(kubeadm version -o short) --pod-network-cidr=10.244.0.0/16 --dry-run \
  && sudo kubeadm init --kubernetes-version $(kubeadm version -o short) --pod-network-cidr=10.244.0.0/16 \
     | sudo tee /tmp/kubeinit.log \
  && echo "Note: the full initialization log can be found on /tmp/kubeinit.log" \
  && mkdir -p $HOME/.kube \
  && sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config \
  && sudo chown $(id -u):$(id -g) $HOME/.kube/config \
  && sudo mkdir -p /root/.kube \
  && sudo cp /etc/kubernetes/admin.conf /root/.kube/config

[ "$?" != 0 ] && echo "ERROR: operation failed. If kubeadm is initialized already and you want to re-initialize, try option --reset" && false
