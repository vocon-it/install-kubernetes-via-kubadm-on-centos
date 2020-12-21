helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add stable https://charts.helm.sh/stable
helm upgrade ingress-nginx ingress-nginx/ingress-nginx --install --create-namespace -n ingress-nginx
