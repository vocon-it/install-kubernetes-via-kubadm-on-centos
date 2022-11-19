
[ "$1" == "-d" ] && CMD=delete || CMD=apply
NUMBER_OF_VOLUMES=${NUMBER_OF_VOLUMES:=100}
OFFSET=${OFFSET:=0}

toLowerFirstChar() {
  _a=${1,}; echo ${_a:0:1}
}

isNotYes() {
  _a=${1,}; [ "${_a:0:1}" != "y" ]
}

# create template
cat > persistentVolume.yaml.tmpl << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ${VOLUME_NAME_PREFIX}-vol${i}
spec:
  capacity:
    storage: 500Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: my-local-storage-class
  local:
    path: ${DISK}/vol${i}
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - ${NODE}
EOF

# old: detect latest volume from df:
#export DISK=${DISK:=$(df | grep mnt | tail -n 1 | awk '{print $6}')}
# new: detect latest Volume starting with name 'HC':
export DISK=${DISK:=$(cat /etc/fstab | grep '/mnt/HC' | cut -d' ' -f2 | tail -1)}
export VOLUME_NAME_PREFIX=$(echo $DISK | awk -F'/mnt/' '{print $2}' | sed -e 's/\(.*\)/\L\1/' | sed 's,_,-,g')
export NODE=$(hostname)

echo DISK=$DISK
echo VOLUME_NAME_PREFIX=$VOLUME_NAME_PREFIX
echo NODE=$NODE

read -p 'Execute? (y/n) ' answer
isNotYes $answer && echo exiting... && exit

for i in $(seq $OFFSET $((OFFSET + NUMBER_OF_VOLUMES -1)));
do
  export i=$i

  if [ "$CMD" == "apply" ]; then
    # create directory on the node, where the PODs will be located (current node in our case):
    DIRNAME="vol${i}"
    sudo test -d ${DISK}/$DIRNAME || sudo mkdir -p ${DISK}/$DIRNAME
    sudo chcon -Rt svirt_sandbox_file_t ${DISK}/$DIRNAME
    sudo chmod 777 ${DISK}/$DIRNAME
  fi
  # create persistentVolume
  [ "$DEBUG" != "" ] && cat persistentVolume.yaml.tmpl | envsubst 
  cat persistentVolume.yaml.tmpl | envsubst | kubectl apply -f -
done    

# cleaning
rm persistentVolume.yaml.tmpl
