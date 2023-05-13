#!/usr/bin/env bash

# run in the directory, where $0 is located:
DIR="$(cd $(dirname $0); pwd)" && cd "${DIR}" 

# check, if sudo is supported:
sudo echo supported > /dev/null 2>/dev/null || alias sudo=$@

# remove obsolete namespaces:
OBSOLETE_NAMESPACES="$(kubectl get ns | egrep -v "^NAME|default" | awk '{print $1}' | while read NS; do echo "$NS $(kubectl -n $NS get pvc | grep -v NAME | awk '{print $1" "$2}' || echo pvc deleted)"; done | grep "intellij-desktop Pending" | awk '{print$1}')"
[ "${OBSOLETE_NAMESPACES}" != "" ] && kubectl delete ns $OBSOLETE_NAMESPACES

