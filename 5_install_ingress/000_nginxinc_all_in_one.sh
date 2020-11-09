
# Install NginX INC Controller 
# Official Documentation: see https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests

#RELEASE=master
RELEASE=release-1.9
RAW_URL="https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments"

NAMESPACE_AND_SERVICEACCOUNT=common/ns-and-sa.yaml
RBAC="rbac/rbac.yaml rbac/ap-rbac.yaml"
COMMOM="common/default-server-secret.yaml common/nginx-config.yaml common/ingress-class.yaml"
CUSTOM_RESOURCES="common/vs-definition.yaml common/vsr-definition.yaml common/ts-definition.yaml common/policy-definition.yaml common/gc-definition.yaml common/global-configuration.yaml"
APP_PROJECT="common/ap-logconf-definition.yaml common/ap-policy-definition.yaml"
NGINX_INGRESS=daemon-set/nginx-ingress.yaml
ALL="$NAMESPACE_AND_SERVICEACCOUNT $RBAC $COMMOM $CUSTOM_RESOURCES $APP_PROJECT $NGINX_INGRESS"

for YAML in $ALL
do
  if [ "${YAML}" == "daemon-set/nginx-ingress.yaml" ]; then
    curl -s "${RAW_URL}/${YAML}" | sed 's/terminationMessagePolicy: File/terminationMessagePolicy: FallbackToLogsOnError/' \
     | kubectl apply -f -
  else
    kubectl apply -f "${RAW_URL}/${YAML}"
  fi
done

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

