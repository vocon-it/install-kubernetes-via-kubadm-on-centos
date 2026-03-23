#!/usr/bin/env bash

NODE=$(hostname)
unset MONITORING_ENVIRONMENT FQDN_SNIPPET
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="$(echo "$NODE" | egrep -q '^dev-.*singapore' && echo dev-singapore)"}
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="$(echo "$NODE" | egrep -q 'singapore' && echo prod-singapore)"}
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="$(echo "$NODE" | egrep -q '^dev-.*helsinki' && echo dev-helsinki)"}
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="$(echo "$NODE" | egrep -q 'helsinki' && echo prod-helsinki)"}
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="$(echo "$NODE" | egrep -q '^dev-' && echo dev-nbg)"}
MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT:="prod-nbg"}
FQDN_SNIPPET=$(
  [ "$MONITORING_ENVIRONMENT" == "dev-singapore" ] && echo "-singapore.dev."
  [ "$MONITORING_ENVIRONMENT" == "prod-singapore" ] && echo "-singapore."
  [ "$MONITORING_ENVIRONMENT" == "dev-helsinki" ] && echo "-helsinki.dev."
  [ "$MONITORING_ENVIRONMENT" == "prod-helsinki" ] && echo "-helsinki."
  [ "$MONITORING_ENVIRONMENT" == "dev-nbg" ] && echo ".dev."
  [ "$MONITORING_ENVIRONMENT" == "prod-nbg" ] && echo "."
)

echo "MONITORING_ENVIRONMENT=$MONITORING_ENVIRONMENT"
echo "FQDN_SNIPPET=$FQDN_SNIPPET"
if [ "$MONITORING_ENVIRONMENT" == "" ]; then
  echo "ERROR: MONITORING_ENVIRONMENT is not set!"
  exit 1
fi
if [ "$FQDN_SNIPPET" == "" ]; then
  echo "ERROR: FQDN_SNIPPET is not set!"
  exit 1
fi

sleep 2

find-available-volumes-of-the-current-host() {
  get-persistent-volumes() {
    kubectl get pv -o=json 2>/dev/null
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
    #SORT=${SORT:=memory};
    SORT=${SORT:=cpu};
    PATTERN=$2;
    PATTERN=${PATTERN:=intellij-desktop|idle-timeout};
    echo "$(kubectl top pod --all-namespaces --use-protocol-buffers | head -1) NODE AGE";
    kubectl top pod --no-headers --all-namespaces --use-protocol-buffers --sort-by=$SORT | egrep --color=auto "^NAME|${PATTERN}" | while read LINE; do
        NODE=$(kubectl -n $(echo $LINE | awk '{print $1}') get pod $(echo $LINE | awk '{print $2}') -o=jsonpath='{.spec.nodeName}');
        AGE=$(kubectl -n $(echo $LINE | awk '{print $1}') get  pod $(echo $LINE | awk '{print $2}') | tail -1 | awk '{print $5}');
        echo "$LINE      $NODE      $AGE";
    done ) | column -t
}



while true; do
  OUT="watch: $0
### MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT} ###
"
  LOGS="$(kubectl -n get-desktop get pod -o json | jq -r .items[].metadata.name | xargs -l kubectl -n get-desktop logs)"
  UNAUTHORIZED_RESPONSES=$(echo "${LOGS}" | grep Writing | grep error=Unauthorized | wc -l)
  COMPLETED_OK=$(echo "${LOGS}" | grep Writing | grep url | wc -l)
  NOT_FOUND_RESPONSES=$(echo "${LOGS}" | grep '404 NOT_FOUND' | wc -l)
  TOTAL_RESPONSES=$(( $(echo "${LOGS}" | grep Writing | grep -v memory | wc -l) + $NOT_FOUND_RESPONSES ))

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
$(df | egrep -v '^devtmpfs|^tmpfs|^overlay|^shm')
"

#$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' | head -8)
  OUT="$OUT
kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=cpu | egrep '^NAME|intellij-desktop' # enriched with NODE and AGE
$(ktop cpu intellij-desktop)
"

  OUT="$OUT
Statistics:
200 OK: $COMPLETED_OK/$TOTAL_RESPONSES
401 Unauthorized: $UNAUTHORIZED_RESPONSES/$TOTAL_RESPONSES
404 Not Found: $NOT_FOUND_RESPONSES/$TOTAL_RESPONSES
500 ERROR or other: $(( $TOTAL_RESPONSES - $COMPLETED_OK - $UNAUTHORIZED_RESPONSES - $NOT_FOUND_RESPONSES ))/$TOTAL_RESPONSES
"

  OUT="$OUT
Last Response:
$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod | tail -1 | cut -d' ' -f1) | tail -1)
"

  OUT="$OUT
Number of available Volumes: $(kubectl get pv | grep Avail | wc -l)
Number of available Volumes on the current host: $(find-available-volumes-of-the-current-host | wc -l)
"

  curl -m 10 -s -L https://cloud${FQDN_SNIPPET}vocon-it.com | grep -q "vocon cloud" \
  || OUT="$OUT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
!!!!!!!!!!!!! FATAL ERROR: cannot reach cloud${FQDN_SNIPPET}vocon-it.com
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
"

  curl -m 10 -s -L https://get-desktop${FQDN_SNIPPET}vocon-it.com | grep -q 401 \
  || OUT="$OUT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!! FATAL ERROR: cannot reach get-desktop${FQDN_SNIPPET}vocon-it.com
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

  sudo kubectl get nodes >/dev/null 2>/dev/null\
  || OUT="$OUT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!! FATAL ERROR: root kubectl does not work! Need to update /root/.kube/config?
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"

  OUT="$OUT
Letsencrypt (https) expire dates on ${MONITORING_ENVIRONMENT}:
$(curl https://cloud${FQDN_SNIPPET}vocon-it.com -vI 2>&1 | grep expire | sed 's/expire/intellij-frontend expire/')
$(curl https://get-desktop${FQDN_SNIPPET}vocon-it.com -vI 2>&1 | grep expire | grep expire | sed 's/expire/get-desktop expire/')
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

