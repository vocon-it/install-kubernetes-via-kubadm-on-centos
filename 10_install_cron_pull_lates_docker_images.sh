#!/usr/local/bin/env bash

[ "${DEBUG}" == "true" ] && set -x
set -e

usage() {
  echo "usage: [DEBUG=true] $0 schedule install_file_path [image1 [image2 ...]]"
  echo "e.g.:  bash $0 '*/15 * * * *' /root/.docker/cron_pull_latest.sh vocon/intellij-desktop vocon/deploy-intellij-desktop"
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
  echo "e.g.:  $0 vocon/intellij-desktop vocon/deploy-intellij-desktop"
}

# split input parameters in lines:
LATEST_IMAGES="$(echo $@ | tr '/' '\n')"

# add latest images found via 'docker images':
LATEST_IMAGES="${LATEST_IMAGES}
docker login
$(docker images | grep latest | awk '{print $1}')
"

# remove duplicates:
LATEST_IMAGES="$(echo "${LATEST_IMAGES}" | egrep -v '^[ ]*$' | sort | uniq)"

# pull:
for LATEST_IMAGE in $LATEST_IMAGES
do
  docker pull $LATEST_IMAGE
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
