# master: ~/install-kubernetes-via-kubadm-on-centos/11_kubernetes_maintenance/12_clean_obsolete_jobs_and_deployments.sh
echo Number of PODS:
for NODE in node1 node2
do
NUMBER_OF_PODS=$(kubectl get pod -A -o wide | egrep 'Running|Pending' | grep $NODE | wc -l)
echo "${NODE}: ${NUMBER_OF_PODS}"
done

# remove old jobs thet were not completed (i.e. errored and pending jobs)
kubectl -n deploy-intellij-desktop get job | grep 0/1 | egrep '[0-9]{2,2}m$' | cut -d ' ' -f 1 | while read JOB; do kubectl -n deploy-intellij-desktop delete job/$JOB; done

# scale down old Pending intellij-desktops:
kubectl get deploy -A | grep 0/1 | grep intellij-desktop | egrep '[0-9]{2,2}m$' | while read NAMESPACE DEPLOY REST; do kubectl -n $NAMESPACE scale deploy/$DEPLOY --replicas=0; done

# scale down obsolete idle-timeout deployments:
EXCLUDE_PATTERN=$(kubectl get deploy -A | grep /1 | grep intellij-desktop | cut -d' ' -f 1 | tr '\n' '|' | sed 's/|$//')
kubectl -n idle-timeout get deploy | grep /1 | egrep -v "${EXCLUDE_PATTERN}" | while read DEPLOY REST; do kubectl -n idle-timeout scale deploy/$DEPLOY --replicas=0; done

# Print number of pods on this host:
echo Number of remaining PODS:
for NODE in node1 node2
do
NUMBER_OF_PODS=$(kubectl get pod -A -o wide | egrep 'Running|Pending' | grep $NODE | wc -l)
echo "${NODE}: ${NUMBER_OF_PODS}"
done


