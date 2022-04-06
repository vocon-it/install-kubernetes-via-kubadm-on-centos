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

  TOTAL_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | wc -l)
  UNAUTHORIZED_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep error=Unauthorized | wc -l)
  COMPLETED_OK=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep 'Completed 200 OK' | wc -l)

  OUT="$OUT
Free Mem of node: $(free -h | egrep '^Mem:' | awk '{print $7}')
"

  OUT="$OUT
$(kubectl describe nodes ${NODE} | grep -A 100 Allocated)
"

  OUT="$OUT
$(df | grep -v docker)
"

  OUT="$OUT
kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | head -8
$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | head -8)
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

  clear
  echo "$OUT"
  sleep 2
done

