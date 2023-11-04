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

ktop ()
{
    # prints k top pod -A, enriched with node information
    # try: ktop memory intellij-desktop (default) or ktop cpu kube-system
    ( SORT=$1;
    SORT=${SORT:=memory};
    PATTERN=$2;
    PATTERN=${PATTERN:=intellij-desktop};
    echo "$(kubectl top pod --all-namespaces --use-protocol-buffers | head -1) NODE";
    kubectl top pod --no-headers --all-namespaces --use-protocol-buffers --sort-by=$SORT | egrep --color=auto "^NAME|${PATTERN}" | while read LINE; do
        NODE=$(kubectl -n $(echo $LINE | awk '{print $1}') get pod $(echo $LINE | awk '{print $2}') -o=jsonpath='{.spec.nodeName}');
        echo "$LINE      $NODE";
    done ) | column -t
}



while true; do
  OUT="watch: $0
"

  TOTAL_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep -v memory | wc -l)
  UNAUTHORIZED_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep error=Unauthorized | wc -l)
  COMPLETED_OK=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep Writing | grep url | wc -l)
  NOT_FOUND_RESPONSES=$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | grep '404 NOT_FOUND' | wc -l)

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

#$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' | head -8)
  OUT="$OUT
kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' # enriched with NODE
$(ktop memory intellij-desktop)
"

  OUT="$OUT
Statistics:
200 OK: $COMPLETED_OK/$TOTAL_RESPONSES
401 Unauthorized: $UNAUTHORIZED_RESPONSES/$TOTAL_RESPONSES
404 Not Found: $NOT_FOUND_RESPONSES/$TOTAL_RESPONSES
500 ERROR or other: $(( $TOTAL_RESPONSES - $COMPLETED_OK - $UNAUTHORIZED_RESPONSES -$NOT_FOUND_RESPONSES ))/$TOTAL_RESPONSES
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

  # "Errored" PODs, if present (newest first):
  EXCLUDE_PATTERN='Running|Completed|Terminating|ContainerCreating'
  OUT="$OUT
$([ "$(kubectl get pod -A | egrep -v ${EXCLUDE_PATTERN} | wc -l)" -gt 1 ] && echo "Errored PODs:" && kubectl get pod -o wide -A --sort-by=.status.startTime | ( head -1; tac ) | egrep -v ${EXCLUDE_PATTERN})
"

  # Warning: high number of PODs on the current host
  WARNING_THRESHOLD=90
  OUT="$OUT
$([ "$(kubectl get pods -A -o wide | grep $(hostname) | grep Running | wc -l)" -ge ${WARNING_THRESHOLD} ] && echo "Warning: high number of PODs on the current host $(hostname): $(kubectl get pods -A -o wide | grep $(hostname) | grep Running | wc -l)/110 !!!!!!!!!!!!!!!!!!!!!!!!")
"
 

  clear
  # with removal of colors and with removal of trailing empty lines:
  echo "$OUT" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
  sleep 2
done

