
[ "$1" == "-d" ] && CMD=delete || CMD=apply

#kubectl $CMD -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/237a7cd71fd1c0fb3067445bbcf96c34c8d4185b/deployments/common/nginx-config.yaml
# better:
# set max body size and timeout to 2GB and 1200 sec, respectively:

cat << EOF | kubectl $CMD -f -
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
  namespace: nginx-ingress
data:
  client-max-body-size: 2048m
  proxy-connect-timeout: 30s
  proxy-read-timeout: 1200s
  namespace: nginx-ingress
EOF

