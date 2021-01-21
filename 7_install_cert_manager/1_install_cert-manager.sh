checkCertManagerInstallation() {
  kubectl get pods --namespace cert-manager | awk '{print $2}' | grep -c 1/1 | grep 3
}

checkCertManagerInstallation && INSTALLED=true

if [ "$INSTALLED" != "true" ]; then
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.1.0/cert-manager.yaml
else
  exit 0
fi

DEPLOYMENT_INFO=""

for (( i=0; i < 10; i++ ))
do
  DEPLOYMENT_INFO=$(checkCertManagerInstallation)
  echo "${DEPLOYMENT_INFO}"
  if [ "${DEPLOYMENT_INFO}" -eq 3 ]; then
    break
  fi
  sleep 5 
done

if [ ! "${DEPLOYMENT_INFO}" -eq 3 ]; then
  echo "Cert-manager installation was not successful. Exiting..."
  exit 1
fi

