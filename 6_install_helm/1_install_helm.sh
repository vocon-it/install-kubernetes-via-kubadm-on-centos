
if ! helm version > /dev/null; then
  export DESIRED_VERSION=v3.4.1
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
    && bash ./get_helm.sh \
    && rm get_helm.sh
fi
helm version
