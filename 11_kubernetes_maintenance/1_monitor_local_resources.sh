#!/usr/bin/env bash

NODE=$(hostname)

find-available-volumes-of-the-current-host() {
  get-persistent-volumes() {
    kubectl get pv -o=json
  }

  items() {
    jq '.items[]'
  }

  filter-volumes-of-current-host() {
    jq 'select(.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] == "'$(hostname)'")'
  }

  bound() {
    jq 'select(.status.phase == "Available")'
  }

  printname() {
    jq -r '.metadata.name'
  }

  get-persistent-volumes \
    | items \
    | bound \
    | filter-volumes-of-current-host \
    | printname
}



while true; do
  OUT="watch: $0
"

  TOTAL_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep -v memory | wc -l)
  UNAUTHORIZED_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep error=Unauthorized | wc -l)
  COMPLETED_OK=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep url | wc -l)

  OUT="$OUT
Free Mem of node: $(free -h | egrep '^Mem:' | awk '{print $7}')
"

  OUT="$OUT
kubectl top nodes --use-protocol-buffers
$(kubectl top nodes --use-protocol-buffers)
"

  OUT="$OUT
$(kubectl describe nodes ${NODE} | grep -A 100 Allocated)
"

  OUT="$OUT
$(df | grep -v docker | grep -v containerd)
"

  OUT="$OUT
kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' | head -8
$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' | head -8)
"

  OUT="$OUT
Statistics:
200 OK: $COMPLETED_OK/$TOTAL_RESPONSES
401 Unauthorized: $UNAUTHORIZED_RESPONSES/$TOTAL_RESPONSES
500 ERROR or other: $(( $TOTAL_RESPONSES - $COMPLETED_OK - $UNAUTHORIZED_RESPONSES ))/$TOTAL_RESPONSES
"

  OUT="$OUT
Last Response:
$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | tail -1)
"

  OUT="$OUT
Number of available Volumes: $(kubectl get pv | grep Avail | wc -l)
Number of available Volumes on the current host: $(find-available-volumes-of-the-current-host | wc -l)
"

  OUT="$OUT
$(curl -s -L cloud.vocon-it.com | grep -q IntellijFrontend \
  || (
      echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; 
      echo '!!!!!!!!!!!!! FATAL ERROR: cannot reach cloud.vocon-it.com !!!!!!!!!!!!!'
      echo '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'; 
     )
 )
"

  OUT="$OUT
$(curl https://cloud.vocon-it.com -vI 2>&1 | grep expire | sed 's/expire/intellij-frontend expire/')
$(curl https://get-desktop.vocon-it.com -vI 2>&1 | grep expire | grep expire | sed 's/expire/get-desktop expire/')
"

  clear
  echo "$OUT"
  sleep 2
done

