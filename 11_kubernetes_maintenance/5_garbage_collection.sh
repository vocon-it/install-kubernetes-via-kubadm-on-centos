ACTIVE_NAMESPACES_PATTERN=$(kubectl get pod -A | egrep ' intellij-desktop' | awk '{print $1}' | sed 's/ /|/g')
OBSOLETE_IDLE_TIMEOUT_DEPLOYMENTS=$(kubectl -n idle-timeout get deploy | grep '1/1' | awk '{print $1}' | egrep -v "${ACTIVE_NAMESPACES_PATTERN}")

kubectl -n idle-timeout scale deployment --replicas=0 ${OBSOLETE_IDLE_TIMEOUT_DEPLOYMENTS}
