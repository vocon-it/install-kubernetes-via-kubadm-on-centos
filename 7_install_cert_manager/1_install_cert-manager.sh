kubectl get pods --namespace cert-manager | awk '{print $2}' | grep 1/1 && INSTALLED=true

if [ "$INSTALLED" != "true" ]; then
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
fi

