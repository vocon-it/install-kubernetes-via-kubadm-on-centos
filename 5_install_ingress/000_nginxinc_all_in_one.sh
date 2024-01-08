set -e

# See https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-manifests/

NGINXINC_VERSION=${NGINXINC_VERSION:=3.4}

cd /tmp
rm -rf kubernetes-ingress || true
git clone https://github.com/nginxinc/kubernetes-ingress.git
cd kubernetes-ingress
git checkout release-${NGINXINC_VERSION}

# Set up role-based access control (RBAC)
kubectl apply -f deployments/common/ns-and-sa.yaml
kubectl apply -f deployments/rbac/rbac.yaml
#  If you’re planning to use NGINX App Protect or NGINX App Protect DoS, additional roles and bindings are needed.
kubectl apply -f deployments/rbac/ap-rbac.yaml
kubectl apply -f deployments/rbac/apdos-rbac.yaml

# Create common resources
kubectl apply -f examples/shared-examples/default-server-secret/default-server-secret.yaml
kubectl apply -f deployments/common/nginx-config.yaml
kubectl apply -f deployments/common/ingress-class.yaml

# Create custom resources
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v3.4.0/deploy/crds.yaml
#   optional
#     WAF
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v3.4.0/deploy/crds-nap-waf.yaml
#     DoS
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v3.4.0/deploy/crds-nap-dos.yaml

# Deploy NGINX Ingress Controller
#   Using a DaemonSet
kubectl apply -f deployments/daemon-set/nginx-ingress.yaml
kubectl apply -f deployments/daemon-set/nginx-plus-ingress.yaml

watch kubectl get pods --namespace=nginx-ingress

