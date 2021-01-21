kubectl get pods --namespace cert-manager | awk '{print $2}' | grep -c 1/1 | grep 3 && INSTALLED=true

if [ "$INSTALLED" != "true" ]; then
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
fi

for (( i=0; i < 10; i++ ))
do
  echo $i
done