
[ "$1" == "-d" ] && CMD=delete || CMD=apply

cat << EOF | kubectl $CMD -f -
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: my-local-storage-class
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF

