NUMBER_OF_INGRESS_PODS_RUNNING=$(kubectl get pods -n nginx-ingress | grep '^nginx-ingress' | grep -c ' Running ' )
NUMBER_OF_INGRESS_PODS_TOTAL=$(kubectl get pods -n nginx-ingress | grep -c '^nginx-ingress' )

[ "$NUMBER_OF_INGRESS_PODS_RUNNING" == "$NUMBER_OF_INGRESS_PODS_TOTAL" ] && true || false

