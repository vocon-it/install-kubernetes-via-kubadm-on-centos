#!/usr/bin/env bash 

set -x

crypto-delete-deployments() {

  kubectl top pod --all-namespaces --use-protocol-buffers --no-headers --sort-by=cpu \
    | egrep ook \
    | while read NAMESPACE NAME CPU RAM;
      do
        CPU_MILLIS=$(echo $CPU | sed 's/m//');
        if [ $CPU_MILLIS -gt 500 ]; then
          echo "CPU_MILLIS=$CPU_MILLIS";
          echo "$NAMESPACE: $CPU_MILLIS";
          if kubectl -n $NAMESPACE exec deploy/intellij-desktop -- ps -aux --sort -%cpu | head -10 | egrep 'xmrig|idle.py|BABYDOGE|packetcrypt|crypt|monero|hashvault.pro'
          then
            # monero: reduce configured CPU to 1%
            kubectl -n $NAMESPACE exec deploy/intellij-desktop -- bash -c 'find . -name config.json | while read CONFIG_JSON; do cat $CONFIG_JSON | grep max-threads-hint | sed -i '\''s/"max-threads-hint":.*/"max-threads-hint": 1,/g'\'' $CONFIG_JSON; done'
            # delete deployment
            kubectl -n $NAMESPACE delete deploy/intellij-desktop;
          elif [  $CPU_MILLIS -gt 3800 ]; then
            kubectl -n $NAMESPACE delete deploy/intellij-desktop;
          fi
        else
          break;
        fi;
      done
}

crypto-delete-deployments

