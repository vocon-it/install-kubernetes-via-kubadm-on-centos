
if ! helm version; then
  curl -s -o helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.12.1-linux-amd64.tar.gz \
    && tar -zxvf helm.tar.gz \
    && cp -p -f linux-amd64/helm /usr/local/bin/ \
    && helm init
fi
