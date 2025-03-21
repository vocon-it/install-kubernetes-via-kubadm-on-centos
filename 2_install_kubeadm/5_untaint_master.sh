
kubectl taint nodes --all node-role.kubernetes.io/master- || true
kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- || true

