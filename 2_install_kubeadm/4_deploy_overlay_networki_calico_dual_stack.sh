

# Exit on error
set -e

# From https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart

# Install the Tigera Calico operator and custom resource definitions.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml

# 2. Install Calico by creating the necessary custom resource. For more information on configuration options available in this manifest, see the installation reference.
#kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# However, we had to replace the callico CIDR Network:
curl -L https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml \
  | sed 's/192\.168/10.244/g' | kubectl apply -f -

watch kubectl get pods -n calico-system

echo success
