#!/usr/bin/env bash

#
# run in the directory, where $0 is located:
#

DIR="$(cd $(dirname $0); pwd)" && cd "${DIR}" 

#
# check, if sudo is supported:
#

sudo echo supported > /dev/null 2>/dev/null || alias sudo=$@

#
# remove obsolete namespaces:
#

OBSOLETE_NAMESPACES="$(kubectl get ns | egrep -v "^NAME|default" | awk '{print $1}' | while read NS; do echo "$NS $(kubectl -n $NS get pvc | grep -v NAME | awk '{print $1" "$2}' || echo pvc deleted)"; done | grep "intellij-desktop Pending" | awk '{print$1}')"
[ "${OBSOLETE_NAMESPACES}" != "" ] && kubectl delete ns $OBSOLETE_NAMESPACES

#
# remove obsolete ingresses:
#

NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE="$(kubectl top pod --all-namespaces --use-protocol-buffers --sort-by=memory | egrep ' intellij-desktop' | awk '{print $1}')"

if [ "$NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE" != "" ]; then
  echo NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE:
  echo "$NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE"
  EXCLUDE_PATTERN=$(echo $NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE | sed 's/ /|/g')
  # EXCLUDE_PATTERN looks similar to follows: 
  # 'jb9pzsgta2grgaoyyuaz8zvcnqw2|juvonn5uovuv88iaw0tpsjkyqqy1|dswdvqbsd3eoo8xfzfrlkmyybb22'
else
  echo no NAMESPACES_TO_BE_EXCLUDED_BECAUSE_IS_ACTIVE found
  EXCLUDE_PATTERN=EMPTY_EXCLUDE_PATTERN
  # EXCLUDE_PATTERN is 'EMPTY_EXCLUDE_PATTERN', which does not match any namespace name
fi

NAMESPACES_TO_BE_CLEANED=$(kubectl get ingress -A | egrep ' intellij-desktop .*[1-9][0-9]+d$' | egrep -v ${EXCLUDE_PATTERN} | cut -d' ' -f 1)

if [ "$NAMESPACES_TO_BE_CLEANED" != "" ]; then
  echo "NAMESPACES_TO_BE_CLEANED:"
  echo "$NAMESPACES_TO_BE_CLEANED"
  echo "$NAMESPACES_TO_BE_CLEANED" \
  | while read n; do kubectl -n $n delete ingress intellij-desktop; sleep 1; done
else
  echo no NAMESPACES_TO_BE_CLEANED found
fi
