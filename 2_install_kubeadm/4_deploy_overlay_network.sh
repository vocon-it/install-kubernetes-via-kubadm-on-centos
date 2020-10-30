
set -e 

# for sourced scripts, set EXIT to "return"
EXIT=${EXIT:=exit}

sudo sysctl net.bridge.bridge-nf-call-iptables=1 \
  && sudo kubectl apply -f "https://cloud.weave.works/k8s/v1.10/net.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')" || ${EXIT} 1


# Check, whether node is ready:
INTERVAL=4
INCREASE=2
for i in $(seq 0 9)
do
  kubectl get nodes | grep " Ready " && ${EXIT} 0
  echo "Node not ready. Waiting for $INTERVAL seconds and trying again"
  sleep $INTERVAL
  INTERVAL=$(expr $INTERVAL + $INCREASE)
done

echo "ERROR: failed to get node ready"
${EXIT} 1

