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
--> Install cert-manager

# HTTPS
## Install cert-manager
### Installation
```shell script
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml

# output:
customresourcedefinition.apiextensions.k8s.io/certificaterequests.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/certificates.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/challenges.acme.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/clusterissuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/issuers.cert-manager.io created
customresourcedefinition.apiextensions.k8s.io/orders.acme.cert-manager.io created
namespace/cert-manager created
serviceaccount/cert-manager-cainjector created
serviceaccount/cert-manager created
serviceaccount/cert-manager-webhook created
clusterrole.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrole.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
clusterrole.rbac.authorization.k8s.io/cert-manager-view created
clusterrole.rbac.authorization.k8s.io/cert-manager-edit created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-cainjector created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-issuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-clusterissuers created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-certificates created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-orders created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-challenges created
clusterrolebinding.rbac.authorization.k8s.io/cert-manager-controller-ingress-shim created
role.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
role.rbac.authorization.k8s.io/cert-manager:leaderelection created
role.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
rolebinding.rbac.authorization.k8s.io/cert-manager-cainjector:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager:leaderelection created
rolebinding.rbac.authorization.k8s.io/cert-manager-webhook:dynamic-serving created
service/cert-manager created
service/cert-manager-webhook created
deployment.apps/cert-manager-cainjector created
deployment.apps/cert-manager created
deployment.apps/cert-manager-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
validatingwebhookconfiguration.admissionregistration.k8s.io/cert-manager-webhook created
```
### Verify cert-manager Installation
```shell script
$ kubectl get pods --namespace cert-manager
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-5597cff495-lczhs             1/1     Running   0          2m27s
cert-manager-cainjector-bd5f9c764-cfwv2   1/1     Running   0          2m27s
cert-manager-webhook-5f57f59fbc-zsc25     1/1     Running   0          2m27s
```
### Test cert-manager Installation
Create manifest file:
```shell script
cat <<EOF > test-resources.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cert-manager-test
---
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: test-selfsigned
  namespace: cert-manager-test
spec:
  selfSigned: {}
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-cert
  namespace: cert-manager-test
spec:
  dnsNames:
    - example.com
  secretName: selfsigned-cert-tls
  issuerRef:
    name: test-selfsigned
EOF
```
Apply manifest-file:
```shell script
kubectl apply -f test-resources.yaml

# output:
namespace/cert-manager-test created
issuer.cert-manager.io/test-selfsigned created
certificate.cert-manager.io/selfsigned-cert created
```
Verify
```shell script
kubectl describe certificate -n cert-manager-test | less

# output:
...
Spec:
  Dns Names:
    example.com
  Issuer Ref:
    Name:       test-selfsigned
  Secret Name:  selfsigned-cert-tls
Status:
  Conditions:
    Last Transition Time:  2020-12-13T15:35:53Z
    Message:               Certificate is up to date and has not expired
    Reason:                Ready
    Status:                True
    Type:                  Ready
  Not After:               2021-03-13T15:35:53Z
  Not Before:              2020-12-13T15:35:53Z
  Renewal Time:            2021-02-11T15:35:53Z
  Revision:                1
Events:
  Type    Reason     Age   From          Message
  ----    ------     ----  ----          -------
  Normal  Issuing    98s   cert-manager  Issuing certificate as Secret does not exist
  Normal  Generated  98s   cert-manager  Stored new private key in temporary Secret resource "selfsigned-cert-jmzmq"
  Normal  Requested  98s   cert-manager  Created new CertificateRequest resource "selfsigned-cert-cjrsh"
  Normal  Issuing    98s   cert-manager  The certificate has been successfully issued
```
Cleaning:
```shell script
kubectl delete -f test-resources.yaml
```
