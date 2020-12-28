# Installing Kubernetes on CentOS

## TODO
- [ ] [DNS]: Add Instructions (here and on phase1 Readme?) on how to add DNS entries for the machine(s)
  - [ ] [DNS] A records for each machine
  - [ ] [DNS] CNAME from master.xxx -> master1.<cluster>.vocon-it.com or the single machine vocon-xxxx.vocon-it.com
- [ ] [DNS] Automated DNS records per CloudFlare API: create JIRA story
- [ ] [Cluster Support] Roles: master and/or slave

```
cd ~centos
[ -d install-kubernetes-via-kubadm-on-centos ] || git clone https://github.com/vocon-it/install-kubernetes-via-kubadm-on-centos.git
cd install-kubernetes-via-kubadm-on-centos/
git checkout feature/CAAS-340-create-a-new-prod-cluster
bash 000_all_in_one.sh
```

This command will install various tools needed for running Kubernetes:
--> Install Docker.
--> Verify previous installation and install kubeadm.
--> Will reset kubeadm.
--> Deploy an overlay network.
--> Untaint the master for runnning pods on the master.
--> Create persistent volumes.
