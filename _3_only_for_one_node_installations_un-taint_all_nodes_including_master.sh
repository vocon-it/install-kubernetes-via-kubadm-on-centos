
kubectl taint nodes --all node-role.kubernetes.io/master-
kubectl taint nodes --all node.kubernetes.io/not-ready:NoExecute-
kubectl taint nodes --all node.kubernetes.io/not-ready:NoSchedule-
