# Installing Kubernetes on CentOS

```
[ -d install-kubernetes-via-kubadm-on-centos ] && git clone https://github.com/vocon-it/install-kubernetes-via-kubadm-on-centos.git
cd install-kubernetes-via-kubadm-on-centos/
bash 000_all_in_one.sh
```

This command will install various tools needed for running Kubernetes:
--> Install Docker.
--> Verify previous installation and install kubeadm.
--> Will reset kubeadm.
--> Deploy an overlay network.
--> Untaint the master for runnning pods on the master.
--> Create persistent volumes.
