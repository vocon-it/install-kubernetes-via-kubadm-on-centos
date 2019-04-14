
[ "$1" == "-d" ] && CMD=delete || CMD=apply

kubectl $CMD -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/237a7cd71fd1c0fb3067445bbcf96c34c8d4185b/deployments/common/ns-and-sa.yaml
