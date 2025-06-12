
# Install NginX INC Controller 
# Official Documentation: see https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests

usage() {
  echo "usage: [NGINXINC_BRANCH=release-2.0] bash $0 [-d]"
  echo "       -d delete"
}

[ $# -gt 1 ] && usage && exit 1
[ $# -eq 1 ] && [ "$1" != "-d" ]  && usage && exit 1

[ "$1" == "-d" ] && CMD=delete || CMD=apply
#NGINXINC_BRANCH=master
#NGINXINC_BRANCH=${NGINXINC_BRANCH:=release-1.9} # Note: '1.9' is a moving target and it refers to 1.9.1, currently (as of 2021-01-03)
#NGINXINC_BRANCH=${NGINXINC_BRANCH:=release-2.0} # Note: '2.0' is a moving target and it refers to 2.0.3, currently (as of 2021-11-06)
NGINXINC_BRANCH=${NGINXINC_BRANCH:=release-4.0} # Note: '4.0' is a moving target and it refers to 4.0.1, currently (as of 2025-03-29)
BASE_URL="https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${NGINXINC_BRANCH}/"

# choose the environment, where to deploy the NginX controller by choosing the KUBECONFIG file:
DEPLOY_ON_ENVIRONMENT=${DEPLOY_ON_ENVIRONMENT:=local}
toLower() {
   sed -e 's/\(.*\)/\L\1/'
}
export KUBECONFIG=${KUBECONFIG:=$( [ "${DEPLOY_ON_ENVIRONMENT}" != "local" ] && echo ~/.kube/${DEPLOY_ON_ENVIRONMENT}-config | toLower || echo ~/.kube/config )}

if [ "${NGINXINC_BRANCH}" == "release-1.9" ]; then
  NAMESPACE_AND_SERVICEACCOUNT=common/ns-and-sa.yaml
  RBAC="rbac/rbac.yaml rbac/ap-rbac.yaml"
  COMMOM="common/default-server-secret.yaml common/nginx-config.yaml common/ingress-class.yaml"
  CUSTOM_RESOURCES="common/vs-definition.yaml common/vsr-definition.yaml common/ts-definition.yaml common/policy-definition.yaml common/gc-definition.yaml common/global-configuration.yaml"
  APP_PROJECT="common/ap-logconf-definition.yaml common/ap-policy-definition.yaml"
  NGINX_INGRESS=daemon-set/nginx-ingress.yaml
  ALL="$NAMESPACE_AND_SERVICEACCOUNT $RBAC $COMMOM $CUSTOM_RESOURCES $APP_PROJECT $NGINX_INGRESS"
elif [ "${NGINXINC_BRANCH}" == "release-2.0" ]; then # see https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests as of 2021-11-06
  ALL="
      deployments/common/ns-and-sa.yaml
      deployments/rbac/rbac.yaml
      deployments/rbac/ap-rbac.yaml
      deployments/common/default-server-secret.yaml
      deployments/common/nginx-config.yaml
      deployments/common/ingress-class.yaml
      deployments/common/crds/k8s.nginx.org_virtualservers.yaml
      deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
      deployments/common/crds/k8s.nginx.org_transportservers.yaml
      deployments/common/crds/k8s.nginx.org_policies.yaml
      deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml
      deployments/common/crds/appprotect.f5.com_aplogconfs.yaml
      deployments/common/crds/appprotect.f5.com_appolicies.yaml
      deployments/common/crds/appprotect.f5.com_apusersigs.yaml
      deployments/daemon-set/nginx-ingress.yaml
    "
elif [ "${NGINXINC_BRANCH}" == "release-4.0" ]; then
  ALL="
      deployments/common/ns-and-sa.yaml
      deployments/rbac/rbac.yaml
      deployments/rbac/ap-rbac.yaml
      deployments/common/nginx-config.yaml
      deployments/common/ingress-class.yaml
      config/crd/bases/k8s.nginx.org_virtualservers.yaml
      config/crd/bases/k8s.nginx.org_virtualserverroutes.yaml
      config/crd/bases/k8s.nginx.org_transportservers.yaml
      config/crd/bases/k8s.nginx.org_policies.yaml
      config/crd/bases/k8s.nginx.org_globalconfigurations.yaml
      config/crd/bases/appprotect.f5.com_aplogconfs.yaml
      config/crd/bases/appprotect.f5.com_appolicies.yaml
      config/crd/bases/appprotect.f5.com_apusersigs.yaml
      deployments/daemon-set/nginx-ingress.yaml
      deployments/service/nodeport.yaml
    "
      # removed from the list even though it is documented on https://docs.nginx.com/nginx-ingress-controller/installation/installing-nic/installation-with-manifests/:
      #   examples/shared-examples/default-server-secret/default-server-secret.yaml
      # but the examples/shared-examples/default-server-secret/default-server-secret.yaml does not exist. 
      # sth. similar exists on 
      #   examples/common-secrets/default-server-secret-NGINXIngressController.yaml
      # but nginx-ingress seems to install without this secret:
      #
      # removed "deployments/service/nodeport.yaml" since it is not needed.
else
  echo ERROR: unsupported/untested version && exit 1
fi

for YAML in $ALL
do
  if [ "${YAML}" == "daemon-set/nginx-ingress.yaml" ]; then
    curl -s "${BASE_URL}/${YAML}" \
      | sed 's/terminationMessagePolicy: File/terminationMessagePolicy: FallbackToLogsOnError/' \
      | sed 's/^        args:/        args:\n          - -enable-snippets/' \
      | kubectl ${CMD} -f -
  else
    kubectl ${CMD} -f "${BASE_URL}/${YAML}"
  fi
done

if [ "${CMD}" == "apply" ]; then
  verify_success() {
    kubectl get pod -n nginx-ingress | grep Running
  }

  for I in $(seq 1 10); do
    verify_success && exit 0
    sleep 10
  done

  echo "POD does not seem to start. Showing log."
  POD=$(kubectl get pod -n nginx-ingress | grep nginx-ingress | head -1 | awk '{print $1}')
  kubectl -n nginx-ingress describe pod $POD | grep -A 100 "Events:"

  echo "If you reach here, then something went wrong in $0"
  exit 1
fi
