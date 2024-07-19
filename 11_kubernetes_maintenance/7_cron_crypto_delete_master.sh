#!/usr/bin/env bash 

set -x

crypto-delete-deployments() {

  # if needed: mount /mnt/u380503.your-storagebox.de/
  bash /home/centos/install-kubernetes-via-kubadm-on-centos/11_kubernetes_maintenance/10_check_and_remount_cifs_storage.sh
  # read config from storagebox:
  [ -r /mnt/u380503.your-storagebox.de/idle-timeout/config.env ] && source /mnt/u380503.your-storagebox.de/idle-timeout/config.env
  CLOUD_DESKTOP_ABUSE_PROCESS_CONFIG="$(curl -s https://raw.githubusercontent.com/vocon-it/cloud-desktop-blacklist/main/blacklist)"
  # read pattern from storagebox. If not found, read the pattern from git:
  CLOUD_DESKTOP_ABUSE_PROCESS_PATTERN="${CLOUD_DESKTOP_ABUSE_PROCESS_PATTERN:=$(echo ${CLOUD_DESKTOP_ABUSE_PROCESS_CONFIG} | awk '{print $1}')}"
  kubectl top pod --all-namespaces --use-protocol-buffers --no-headers --sort-by=cpu \
    | egrep ook \
    | while read NAMESPACE NAME CPU RAM;
      do
        CPU_MILLIS=$(echo $CPU | sed 's/m//');
        if [ $CPU_MILLIS -gt 500 ]; then
          echo "CPU_MILLIS=$CPU_MILLIS";
          echo "$NAMESPACE: $CPU_MILLIS";
          if kubectl -n $NAMESPACE exec deploy/intellij-desktop -- ps -aux --sort -%cpu | head -10 | egrep "${CLOUD_DESKTOP_ABUSE_PROCESS_PATTERN}" \
          || kubectl -n $NAMESPACE exec deploy/intellij-desktop -- cat .bash_history | egrep "${CLOUD_DESKTOP_ABUSE_PROCESS_PATTERN}"
          then
            # monero: reduce configured CPU to 1%
            kubectl -n $NAMESPACE exec deploy/intellij-desktop -- bash -c 'find . -name config.json | while read CONFIG_JSON; do cat $CONFIG_JSON | grep max-threads-hint | sed -i '\''s/"max-threads-hint":.*/"max-threads-hint": 1,/g'\'' $CONFIG_JSON; done'
            # delete deployment
            kubectl -n $NAMESPACE delete deploy/intellij-desktop;
          elif [  $CPU_MILLIS -gt 2500 ]; then
            kubectl -n $NAMESPACE delete deploy/intellij-desktop;
          fi
        else
          break;
        fi;
      done
}

crypto-delete-deployments

