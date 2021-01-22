certManagerUpAndRunning() {
  kubectl get pods --namespace cert-manager | awk '{print $2}' | grep -c 1/1 | grep 3
}

if ! certManagerUpAndRunning; then
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
else
  exit 0
fi

for (( i=0; i < 10; i++ ))
do
  certManagerUpAndRunning && break
  sleep 5 
done

if ! certManagerUpAndRunning; then
  echo "Cert-manager installation was not successful. Exiting..."
  exit 1
fi

