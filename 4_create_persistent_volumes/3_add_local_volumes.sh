
[ "$1" == "-d" ] && CMD=delete || CMD=apply
NUMBER_OF_VOLUMES=${NUMBER_OF_VOLUMES:=100}

# create template
cat > persistentVolume.yaml.tmpl << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: vol${i}
spec:
  capacity:
    storage: 500Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: my-local-storage-class
  local:
    path: /mnt/disk/vol${i}
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
DISK=$(df | grep mnt | tail -n 1 | awk '{print $6}')
if [ "$DISK" != "" ]; then
  answer=yes
  read -t 10 -p "External disk on mountpoint $DISK detected. Use this disk for creating volumes? ($answer) >" answer
  if [ "${answer:0:1}" == "y" -o "${answer:0:1}" == "Y" ]; then
    sudo ln -s $DISK /mnt/disk    
  fi
fi

export NODE=$(hostname)
for i in $(seq 1 $NUMBER_OF_VOLUMES);
do
  export i=$i

  if [ "$CMD" == "apply" ]; then
    # create directory on the node, where the PODs will be located (current node in our case):
    DIRNAME="vol${i}"
    sudo test -d /mnt/disk/$DIRNAME || sudo mkdir -p /mnt/disk/$DIRNAME 
    sudo chcon -Rt svirt_sandbox_file_t /mnt/disk/$DIRNAME
    sudo chmod 777 /mnt/disk/$DIRNAME
  
    # create persistentVolume
    envsubst < persistentVolume.yaml.tmpl > persistentVolume.yaml
  fi
  kubectl $CMD -f persistentVolume.yaml
done    

# cleaning
rm persistentVolume.yaml.tmpl persistentVolume.yaml 
