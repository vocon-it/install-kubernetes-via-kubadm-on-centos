
# install cert-manager, if  not already done:
kubectl get crd 2>/dev/null | grep -q issuers.certmanager.k8s.io && INSTALLED=true

if [ "$INSTALLED" != "true" ]; then
  # Copied from https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager:
  #   changes: namespace set from cert-manager to kube-system, so it fits to the rest

  ## IMPORTANT: you MUST install the cert-manager CRDs **before** installing the
  ## cert-manager Helm chart
  kubectl apply \
      -f https://raw.githubusercontent.com/jetstack/cert-manager/release-0.7/deploy/manifests/00-crds.yaml
  
  ## IMPORTANT: if the cert-manager namespace **already exists**, you MUST ensure
  ## it has an additional label on it in order for the deployment to succeed
  #$ kubectl label namespace cert-manager certmanager.k8s.io/disable-validation="true"
  
  ## Add the Jetstack Helm repository
  helm repo add jetstack https://charts.jetstack.io
  
  ## Add namespace cert-manager if not present
  #kubectl get namespace cert-manager 2>/dev/null || kubectl create namespace cert-manager

  ## Install the cert-manager helm chart
  helm install \
    --name cert-manager \
    --namespace kube-system \
    jetstack/cert-manager
fi

