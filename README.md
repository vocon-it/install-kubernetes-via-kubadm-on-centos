# Installing Kubernetes on CentOS

## TODO
- [ ] [DNS]: Add Instructions (here and on phase1 Readme?) on how to add DNS entries for the machine(s)
  - [ ] [DNS] A records for each machine
  - [ ] [DNS] CNAME from master.xxx -> master1.<cluster>.vocon-it.com or the single machine vocon-xxxx.vocon-it.com
- [ ] [DNS] Automated DNS records per CloudFlare API: create JIRA story
- [ ] [/etc/hosts] Describe how to edit /etc/hosts (e.g. replace `127.0.0.1 <hostname> <hostname>>` by `127.0.0.1 <hostname>.<cluster>.vocon-it.com <hostname>>` 
            and in case of a hostname=master1 optionally add a copied line with `master` instead of `master1` whose FQDN can be used as `CONTROL_PLANE_ENDPOINT`
- [ ] [Cluster Support] Roles: master and/or slave
- [ ] [Cluster Support] Describe how to add an agent node (as opposed to a control node)

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
