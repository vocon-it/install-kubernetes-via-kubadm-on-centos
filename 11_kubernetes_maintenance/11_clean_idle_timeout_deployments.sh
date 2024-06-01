#
# Scales down all idle-timeout deployments, if no user deployment with replicas > 0 is found
#

notEmpty() {
    for _VAR in $@
    do
        [ "${DEBUG}" == "true" ] && echo "DEBUG: notEmpty(): ${_VAR}=${!_VAR}" >&2
        if [ "${!_VAR}" == "" ] || [ "${!_VAR}" == "null" ]; then
            echo "${_VAR} is not defined or empty or null" >&2
            return 1
        fi
    done
}

get_running_idle_timeout_deployments() {
  kubectl -n idle-timeout get deploy | egrep '/[1-9]' | awk '{print $1}'
}

get_active_user_namespaces() {
  kubectl get deploy -A | egrep 'intellij-desktop' | egrep '1/1' | awk '{print $1}' | egrep -v 'jup-'
}


get_user_namespace() {
  notEmpty IDLE_TIMEOUT_DEPLOYMENT
  kubectl -n idle-timeout exec "deploy/${IDLE_TIMEOUT_DEPLOYMENT}" -- bash -c 'echo $DEVELOPERS_CLOUD_DESKTOP_NAMESPACE'
}

is_has_scaled_user_deployments() {
  kubectl -n "$(get_user_namespace)" get deploy | egrep '/[1-9]' 
  #echo "Warning: is_has_scaled_user_deployments function works only, if tracing is switched on inside idle-timeout container" >&2
  #kubectl -n idle-timeout logs deploy/$IDLE_TIMEOUT_DEPLOYMENT | tail -20 | egrep -q ' PODS=$'
}

error() {
  echo "ERROR: $@"
  return 1
}

warning() {
  echo "WARNING: $@"
}

info() {
  echo "INFO: $@"
}


#
# MAIN
#

info Scaling down obsolete idle-timeout deployments
get_running_idle_timeout_deployments \
| while read IDLE_TIMEOUT_DEPLOYMENT
  do 
    echo $IDLE_TIMEOUT_DEPLOYMENT 
    if ! IDLE_TIMEOUT_DEPLOYMENT=${IDLE_TIMEOUT_DEPLOYMENT} is_has_scaled_user_deployments
    then
      kubectl -n idle-timeout scale deploy $IDLE_TIMEOUT_DEPLOYMENT --replicas 0 \
      && info "scaled idle-timeout deployment ${IDLE_TIMEOUT_DEPLOYMENT} to zero replicas" \
      || error "cannot scale idle-timeout deployment ${IDLE_TIMEOUT_DEPLOYMENT} to zero replicas"
    fi
  done

info Scaling up missing idle-timeout deployments
get_active_user_namespaces \
| while read ACTIVE_USER_NAMESPACE
  do
    IDLE_TIMEOUT_DEPLOYMENT=idle-timeout-${ACTIVE_USER_NAMESPACE}
    if kubectl -n idle-timeout get deploy ${IDLE_TIMEOUT_DEPLOYMENT} | egrep -q '/0'
    then
      kubectl -n idle-timeout scale deploy $IDLE_TIMEOUT_DEPLOYMENT --replicas 1 \
      && warning "scaled missing idle-timeout deployment ${IDLE_TIMEOUT_DEPLOYMENT} to one replica" \
      || error "cannot scale missing idle-timeout deployment ${IDLE_TIMEOUT_DEPLOYMENT} to one replica"
    fi
  done 
