usage() {
  echo "usage: $0 [image1 [image2] ...]"
  echo "e.g.:  $0 vocon/intellij-desktop:latest vocon/deploy-intellij-desktop:latest vocon/idle-timeout:latest"
}

# split input parameters in lines:
LATEST_IMAGES="$(echo $@ | tr ' ' '\n')"

# add latest images found via 'docker images':
#docker login
LATEST_IMAGES="${LATEST_IMAGES}
$(docker images | grep latest | awk '{print $1}')
$(sudo ctr -n k8s.io images ls | grep develop | awk '{print $1}' | sed 's_docker.io/__')
"

# remove duplicates:
LATEST_IMAGES="$(echo "${LATEST_IMAGES}" | egrep -v '^[ ]*$' | sort | uniq)"

# detect runtime from kubelet/Kubernetes
RUNTIME=$(kubectl get node "$(hostname)" -o jsonpath='{.status.nodeInfo.containerRuntimeVersion}')

if [[ "$RUNTIME" == docker://* ]]; then
  PULL_COMMAND="docker pull"
elif [[ "$RUNTIME" == containerd://* ]]; then
  PULL_COMMAND="ctr -n k8s.io images pull"
elif [[ "$RUNTIME" == cri-o://* ]]; then
  PULL_COMMAND="crictl pull"
else
  echo "ERROR: No supported RUNTIME=$RUNTIME found!" && exit 1
fi

# is docker installed?
docker --version >/dev/null 2>/dev/null \
&& PULL_DOCKER=true \
|| PULL_DOCKER=false

# pull:
for LATEST_IMAGE in $LATEST_IMAGES
do
  echo $LATEST_IMAGE | grep -q ':' || LATEST_IMAGE=$LATEST_IMAGE:latest
  sudo ${PULL_COMMAND} docker.io/$LATEST_IMAGE
  [ "${PULL_DOCKER}" = "true" ] && docker pull $LATEST_IMAGE  
done



