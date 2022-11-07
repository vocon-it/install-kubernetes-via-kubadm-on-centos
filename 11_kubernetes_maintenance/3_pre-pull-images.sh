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

# pull:
for LATEST_IMAGE in $LATEST_IMAGES
do
  echo $LATEST_IMAGE | grep -q ':' || LATEST_IMAGE=$LATEST_IMAGE:latest
#  docker pull $LATEST_IMAGE
  sudo ctr -n k8s.io images pull docker.io/$LATEST_IMAGE
done

