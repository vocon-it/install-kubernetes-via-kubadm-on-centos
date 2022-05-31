#!/usr/local/bin/env bash

[ "${DEBUG}" == "true" ] && set -x
set -e

usage() {
  echo "usage: [DEBUG=true] $0 schedule install_file_path [image1 [image2 ...]]"
  echo "e.g.:  bash $0 '*/15 * * * *' /root/cron_pull_latest.sh vocon/intellij-desktop:latest vocon/deploy-intellij-desktop:latest vocon/idle-timeout:latest"
}

if [ $# -lt 2 ]; then
  usage && exit 1
fi

SCHEDULE=$1
shift
SCRIPT_FILE=$1
shift
IMAGES="$@"

cat <<'EOF' > ${SCRIPT_FILE}
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
  docker pull $LATEST_IMAGE
  sudo ctr -n k8s.io images pull docker.io/$LATEST_IMAGE
done
EOF

chmod +x ${SCRIPT_FILE}

# update crontab:
_TMP_FILE="/tmp/crontab_$(date +%F--%H-%M-%S)"
crontab -l | grep -v "${SCRIPT_FILE}" > ${_TMP_FILE} || true
echo "${SCHEDULE} ${SCRIPT_FILE} ${IMAGES}" >> ${_TMP_FILE}
crontab ${_TMP_FILE}
rm ${_TMP_FILE}

echo "updated crontab:"
crontab -l
