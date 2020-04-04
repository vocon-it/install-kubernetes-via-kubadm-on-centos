
sudo sysctl net.bridge.bridge-nf-call-iptables=1 \
  && sudo kubectl apply -f "https://cloud.weave.works/k8s/v1.10/net.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"


# Check, whether node is ready:
if [ "$?" == "0" ]; then
  READY=false
  INTERVAL=10
  for i in $(seq 0 9)
  do
    kubectl get nodes | grep " Ready " && READY=true && break
    echo "Node not ready. Waiting for $INTERVAL seconds and trying again"
    sleep $INTERVAL
    INTERVAL=$(expr $INTERVAL + $INTERVAL)
  done
  [ "$READY" != "true" ] && echo "ERROR: failed to get node ready" && exit 1
else
  exit 1
fi

