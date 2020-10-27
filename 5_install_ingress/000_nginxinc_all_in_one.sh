
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

exit 1

###########
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/common/ns-and-sa.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/rbac/rbac.yaml
# if rbac is missing, we get the error in the nginx controller pod:
# Error when getting IngressClass nginx: ingressclasses.networking.k8s.io "nginx" is forbidden: User "system:serviceaccount:nginx-ingress:nginx-ingress" cannot get resource "ingressclasses" in API group "networking.k8s.io" at the cluster scope
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/common/default-server-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/common/nginx-config.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/common/ingress-class.yaml
# if ingress-class is missing, we get following error message:
# Error when getting IngressClass nginx: ingressclasses.networking.k8s.io "nginx" not found
# when applied, we gett following 
# Warning: networking.k8s.io/v1beta1 IngressClass is deprecated in v1.19+, unavailable in v1.22+; use networking.k8s.io/v1 IngressClassList
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/${RELEASE}/deployments/daemon-set/nginx-ingress.yaml

