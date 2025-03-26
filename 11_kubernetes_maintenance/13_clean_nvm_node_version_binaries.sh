

# on each kubernetes worker node:
find /mnt/HC_* -name versions 2>/dev/null | egrep '\.nvm/versions' > /tmp/HC_.nvm.versions

# find active namespaces:
EXCLUDED_NAMESPACES_PATTERN="$(
  kubectl get pod --all-namespaces \
  | egrep ' intellij-desktop' \
  | awk '{print $1}' \
  | tr '\n' '|' \
  | sed 's_|$__'
)"

echo INFO: EXCLUDED_NAMESPACES_PATTERN=$EXCLUDED_NAMESPACES_PATTERN

# remove node versions directories:
cat /tmp/HC_.nvm.versions \
| egrep -v "${EXCLUDED_NAMESPACES_PATTERN}" \
| while read V; 
  do 
    sudo ls -d "${V}" >/dev/null 2>/dev/null \
    && sudo rm -rf "${V}" \
    && echo "INFO: removed ${V}" \
    || echo "ERROR: failed to remove ${V}"
  done

