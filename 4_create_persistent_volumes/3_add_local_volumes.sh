
[ "$1" == "-d" ] && CMD=delete || CMD=apply
NUMBER_OF_VOLUMES=100
OFFSET=0

NUMBER_OF_VOLUMES=${NUMBER_OF_VOLUMES:=100}

# create template
cat > persistentVolume.yaml.tmpl << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: $(echo $DISK | awk -F'/mnt/' '{print $2}')_vol${i}
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

# detect external volumes. If found, use the last external volume in the list
#export DISK=${DISK:=$(df | grep mnt | tail -n 1 | awk '{print $6}')}
# detect latest Volume starting with name 'HC':
export DISK=${DISK:=$(cat /etc/fstab | grep '/mnt/HC' | cut -d' ' -f2 | tail -1)}

#if [ "${DISK}" != "" ]; then
#  sudo ln -s ${DISK} /mnt/disk
#else
#  mkdir /mnt/disk
#fi
#DISK=/mnt/disk
#DISK=${DISK:=/mnt/disk}


export NODE=$(hostname)
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
  cat persistentVolume.yaml.tmpl | envsubst > persistentVolume.yaml
  kubectl $CMD -f persistentVolume.yaml
done    

# cleaning
rm persistentVolume.yaml.tmpl persistentVolume.yaml 
