#!/usr/bin/env bash

export TERM="${TERM:-xterm-256color}" # get rid of the warning: "TERM environment variable not set."

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
    echo "$(kubectl top pod --all-namespaces --use-protocol-buffers 2>/dev/null | head -1) NODE AGE";
    kubectl top pod --no-headers --all-namespaces --use-protocol-buffers --sort-by=$SORT 2>/dev/null | egrep --color=auto "^NAME|${PATTERN}" | while read LINE; do
        NODE=$(kubectl -n $(echo $LINE | awk '{print $1}') get pod $(echo $LINE | awk '{print $2}') -o=jsonpath='{.spec.nodeName}' 2>/dev/null);
        AGE=$(kubectl -n $(echo $LINE | awk '{print $1}') get  pod $(echo $LINE | awk '{print $2}') 2>/dev/null | tail -1 | awk '{print $5}');
        echo "$LINE      $NODE      $AGE";
    done ) | column -t
}



while true; do
  OUT="#############################################################################
### watch: $0
### MONITORING_ENVIRONMENT=${MONITORING_ENVIRONMENT}
### NODE=${NODE}
#############################################################################
"
  LOGS="$(kubectl -n get-desktop get pod -o json 2>/dev/null | jq -r .items[].metadata.name | xargs -l kubectl -n get-desktop logs 2>/dev/null)"
  UNAUTHORIZED_RESPONSES=$(echo "${LOGS}" | grep Writing | grep error=Unauthorized | wc -l)
  COMPLETED_OK=$(echo "${LOGS}" | grep Writing | grep url | wc -l)
  NOT_FOUND_RESPONSES=$(echo "${LOGS}" | grep '404 NOT_FOUND' | wc -l)
  TOTAL_RESPONSES=$(( $(echo "${LOGS}" | grep Writing | grep -v memory | wc -l) + $NOT_FOUND_RESPONSES ))

  OUT="$OUT
Free Mem of node: $(free -h | egrep '^Mem:' | awk '{print $7}')
"

  OUT="$OUT
kubectl top nodes --use-protocol-buffers
$(kubectl top nodes --use-protocol-buffers 2>/dev/null)
"

  OUT="$OUT
$(kubectl describe nodes ${NODE} | grep -A 100 Allocated 2>/dev/null)
"

  OUT="$OUT
$(df | egrep -v '^devtmpfs|^tmpfs|^overlay|^shm')
"

#$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep '^NAME|intellij-desktop' | head -8)
  OUT="$OUT
kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=cpu 2>/dev/null | egrep '^NAME|intellij-desktop' # enriched with NODE and AGE
$(ktop cpu intellij-desktop 2>/dev/null)
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
$(kubectl -n get-desktop logs $(kubectl -n get-desktop get pod 2>/dev/null | tail -1 | cut -d' ' -f1) 2>/dev/null | tail -1)
"

  OUT="$OUT
Number of available Volumes: $(kubectl get pv 2>/dev/null | grep Avail | wc -l)
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

  # Weave overlay health: every peer connection must be "established fastdp".
  # Catches sleeve (degraded UDP fallback), failed/"connection refused" (down),
  # missing peers, and a dead local weave pod -> all break cross-node pod traffic
  # and surface as cloud${FQDN_SNIPPET}vocon-it.com 500s on session spin-up.
  # Only relevant where Weave is installed: if there is no weave-net DaemonSet
  # (e.g. the Singapore cluster uses a different CNI), WEAVE_INSTALLED stays "no"
  # and the alarm never fires. The alarm fires only when Weave IS installed but
  # NOT functional.
  WEAVE_INSTALLED=no; WEAVE_CONN=""; WEAVE_BAD=""; WEAVE_FASTDP=0; WEAVE_EXPECTED=0
  if kubectl -n kube-system get ds weave-net >/dev/null 2>&1; then
    WEAVE_INSTALLED=yes
    WEAVE_POD=$(kubectl -n kube-system get pod -l name=weave-net --field-selector spec.nodeName=$(hostname) -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    WEAVE_CONN=$(kubectl -n kube-system exec "$WEAVE_POD" -c weave -- /home/weave/weave --local status connections 2>/dev/null)
    WEAVE_EXPECTED=$(( $(kubectl get nodes --no-headers 2>/dev/null | wc -l) - 1 ))
    WEAVE_FASTDP=$(echo "$WEAVE_CONN" | grep -c 'established fastdp')
    WEAVE_BAD=$(echo "$WEAVE_CONN" | egrep '(->|<-)' | egrep -v 'established fastdp')
  fi
  if [ "$WEAVE_INSTALLED" == "yes" ] && { [ -n "$WEAVE_BAD" ] || [ "$WEAVE_FASTDP" -lt "$WEAVE_EXPECTED" ]; }; then
  OUT="$OUT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!! FATAL ERROR: Weave overlay DEGRADED on $(hostname)! Expected ${WEAVE_EXPECTED} 'established fastdp' peer(s), found ${WEAVE_FASTDP}.
!!!!!!!!!!!!! Cross-node pod traffic is likely broken -> session spin-up 500s. Do NOT uncordon affected node until fastdp returns.
!!!!!!!!!!!!! weave --local status connections:
$(echo "${WEAVE_CONN:-<no connections / local weave pod unreachable>}" | sed 's/^/!!!!!!!!!!!!! /')
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
  fi

  # Node metrics health: a node reporting <unknown> in 'kubectl top nodes' means
  # metrics-server cannot scrape its kubelet (:10250) -> get-desktop's capacity
  # check sees it as zero-resource -> "no available resources to fulfill your
  # memory request reservation" 500s. Root cause is usually a crash-looping kubelet
  # (check: journalctl -u kubelet for a corrupt pod_status_manager_state panic).
  NODES_NO_METRICS=$(kubectl top nodes --use-protocol-buffers 2>/dev/null | egrep '<unknown>' | awk '{print $1}')
  if [ -n "$NODES_NO_METRICS" ]; then
  OUT="$OUT
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!!!!!!!!!!! FATAL ERROR: node(s) with NO metrics (<unknown> in kubectl top): $(echo $NODES_NO_METRICS | tr '\n' ' ')
!!!!!!!!!!!!! kubelet :10250 unreachable -> 'no available resources' 500s. Check 'journalctl -u kubelet' on the node.
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
"
  fi

  OUT="$OUT
Letsencrypt (https) expire dates on ${MONITORING_ENVIRONMENT}:
$(curl https://cloud${FQDN_SNIPPET}vocon-it.com -vI 2>&1 | grep "expire date:" | sed 's/expire date:/intellij-frontend expire date:/')
$(curl https://get-desktop${FQDN_SNIPPET}vocon-it.com -vI 2>&1 | grep "expire date:" | sed 's/expire date:/get-desktop expire date:/')
"

  # "Errored" PODs, if present (newest first):
  EXCLUDE_PATTERN='Running|Completed|Terminating|ContainerCreating'
  OUT="$OUT
$([ "$(kubectl get pod -A 2>/dev/null | egrep -v ${EXCLUDE_PATTERN} | wc -l)" -gt 1 ] && echo "Errored PODs:" && kubectl get pod -o wide -A --sort-by=.status.startTime 2>/dev/null | ( head -1; tac ) | egrep -v ${EXCLUDE_PATTERN})
"

  # Warning: high number of PODs on the current host
  WARNING_THRESHOLD=90
  OUT="$OUT
$([ "$(kubectl get pods -A -o wide 2>/dev/null | grep $(hostname) | grep Running | wc -l)" -ge ${WARNING_THRESHOLD} ] && echo "Warning: high number of PODs on the current host $(hostname): $(kubectl get pods -A -o wide 2>/dev/null | grep $(hostname) | grep Running | wc -l)/110 !!!!!!!!!!!!!!!!!!!!!!!!")
"
  DOTS=${DOTS}.
  [ "$DOTS" == "..........." ] && DOTS=""

  OUT="$OUT
$([ "$(kubectl get pods -A -o wide 2>/dev/null | grep $(hostname) | grep Running | wc -l)" -ge ${WARNING_THRESHOLD} ] && echo "Warning: high number of PODs on the current host $(hostname): $(kubectl get pods -A -o wide 2>/dev/null | grep $(hostname) | grep Running | wc -l)/110 !!!!!!!!!!!!!!!!!!!!!!!!")
"
  # remove colors and trailing empty lines:
  OUT="$(echo "$OUT" | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')"

  OUT="$OUT
${DOTS}"

  clear
  # with removal of colors and with removal of trailing empty lines:
  echo "$OUT" # | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2};?)?)?[mGK]//g" | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba'
  sleep 2
done

