

DRIVES_TO_BE_CLEANED="/mnt/u380503.your-storagebox.de/user-specific-shared-volumes"
CLEANUP_DRY_RUN=${CLEANUP_DRY_RUN:="true"}

echo Cleaning caches
# [ "${IDLE_CLEANUP_DRY_RUN}" != "false" ] && CLEANUP_DRY_RUN=true || CLEANUP_DRY_RUN=false
CLEANUP_DU_LOG=/tmp/idle_cleanup_du_$(date +%Y%m%d_%H%M%S).log
export CLEANUP_DRY_RUN CLEANUP_DU_LOG
echo "Cleanup du log: ${CLEANUP_DU_LOG}; dry-run=${CLEANUP_DRY_RUN}"
for DRIVE in ${DRIVES_TO_BE_CLEANED}
do
  echo "Cleaning cache, config, partial downloads, core dumps and IndexedDB under ${DRIVE} (single pass)"
  CLEANUP_START=$(date +%s)
  find "${DRIVE}" \( \
      -type d \( \
          -name '.cache' \
          -o -path '*/.nvm/.cache' \
          -o -path '*/.npm/_cacache' \
          -o -path '*/.config/buypremium-nativefier*' \
          -o -path '*/.config/BraveSoftware' \
          -o -path '*/.config/google-chrome/*/CacheStorage' \
          -o -path '*/.config/google-chrome/*/*cache*' \
          -o -path '*/.nvm/test' \
          -o -path '*/.nvm/.git' \
          -o -path '*/.nvm/versions' \
          -o -path '*/.kube/cache' \
          -o -path '*/.config/google-chrome/*/Safe Browsing' \
          -o -path '*/.config/google-chrome/*/IndexedDB' \
      \) -prune \
      -o -type f -iname '*.crdownload' \
      -o -type f -iname '*.part' \
      -o -type f -iname 'core.*' -size +50M \
    \) -exec sh -c '
      for path do
        case "$path" in
          */.nvm/.cache)
            echo "[MATCH] nvm cache: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.npm/_cacache)
            echo "[MATCH] npm _cacache: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.config/buypremium-nativefier*)
            echo "[MATCH] buypremium-nativefier config: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.config/BraveSoftware)
            echo "[MATCH] BraveSoftware config: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.config/google-chrome/*/CacheStorage)
            echo "[MATCH] Chrome CacheStorage: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.config/google-chrome/*/*cache*)
            echo "[MATCH] Chrome *cache* dir: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.nvm/test)
            echo "[MATCH] nvm test dir: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.nvm/.git)
            echo "[MATCH] nvm .git dir: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.nvm/versions)
            echo "[MATCH] nvm versions dir: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          */.kube/cache)
            echo "[MATCH] Kubernetes cache: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          *"/Safe Browsing")
            echo "[MATCH] Chrome Safe Browsing: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          *IndexedDB)
            echo "[MATCH] IndexedDB: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            SIZE=$(du -d 0 "$path" 2>/dev/null | awk "{print \$1}")
            [ -n "${SIZE}" ] && [ "${SIZE}" -gt 20000 ] && [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path" && echo "removed (size ${SIZE} kB)"
            ;;
          */.cache)
            echo "[MATCH] generic .cache dir: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path"
            ;;
          *.crdownload)
            echo "[MATCH] partial download: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -f "$path"
            ;;
          *.part)
            echo "[MATCH] partial download: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -f "$path"
            ;;
          *core.*)
            echo "[MATCH] core dump: $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -f "$path"
            ;;
          *)
            echo "[MATCH] other (unexpected): $path"
            du -d 0 "$path" | tee -a "${CLEANUP_DU_LOG}"
            [ -d "$path" ] && [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -rf "$path" || [ "${CLEANUP_DRY_RUN}" = "false" ] && rm -f "$path"
            ;;
        esac
      done
    ' _ {} +
  CLEANUP_END=$(date +%s)
  echo "Cleanup scan under ${DRIVE} took $((CLEANUP_END - CLEANUP_START)) seconds"

  echo "Files larger than 10G under ${DRIVE}"
  if [ "${CLEANUP_DRY_RUN}" = "false" ]; then
    find "${DRIVE}" -type f -size +10G -exec sh -c 'du -d 0 "$1" | tee -a "${CLEANUP_DU_LOG}"; rm -f "$1"' _ {} \;
  else
    find "${DRIVE}" -type f -size +10G -exec du -d 0 {} \; | tee -a "${CLEANUP_DU_LOG}"
  fi

  echo "CLEANUP_DRY_RUN=${CLEANUP_DRY_RUN}"
  echo "CLEANUP_DU_LOG=${CLEANUP_DU_LOG}"
done