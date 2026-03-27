DRIVES_TO_BE_CLEANED="/mnt/u380503.your-storagebox.de/user-specific-shared-volumes"
CLEANUP_DRY_RUN=${CLEANUP_DRY_RUN:="true"}
UPDATE_CLEANUP_DU_LOG_LATEST=${UPDATE_CLEANUP_DU_LOG_LATEST:="true"}
TMP_DIR=/mnt/u380503.your-storagebox.de/tmp
CLEANUP_DU_LOG_LATEST="${TMP_DIR}/network_drive_cleanup_du_latest.log"
TO_BE_CLEANED="${TMP_DIR}/network_drive_cleanup_to_be_cleaned.log"

mkdir -p "${TMP_DIR}"

run_cleanup_scan() {
  local cleanup_dry_run_local="${CLEANUP_DRY_RUN}"
  local update_cleanup_du_log_latest_local="${UPDATE_CLEANUP_DU_LOG_LATEST}"
  local cleanup_du_log_local="${TMP_DIR}/network_drive_cleanup_du_$(date +%Y%m%d_%H%M%S).log"

  export CLEANUP_DRY_RUN="${cleanup_dry_run_local}"
  export CLEANUP_DU_LOG="${cleanup_du_log_local}"
  echo "Cleanup du log: ${cleanup_du_log_local}; dry-run=${cleanup_dry_run_local}"

  for DRIVE in ${DRIVES_TO_BE_CLEANED}; do
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
    if [ "${cleanup_dry_run_local}" = "false" ]; then
      find "${DRIVE}" -type f -size +10G -exec sh -c 'du -d 0 "$1" | tee -a "${CLEANUP_DU_LOG}"; rm -f "$1"' _ {} \;
    else
      find "${DRIVE}" -type f -size +10G -exec du -d 0 {} \; | tee -a "${CLEANUP_DU_LOG}"
    fi

    echo "CLEANUP_DRY_RUN=${cleanup_dry_run_local}"
    echo "CLEANUP_DU_LOG=${cleanup_du_log_local}"
  done

  if [ "${update_cleanup_du_log_latest_local}" = "true" ]; then
    cp "${cleanup_du_log_local}" "${CLEANUP_DU_LOG_LATEST}"
    echo "Copied ${cleanup_du_log_local} to ${CLEANUP_DU_LOG_LATEST}"
  fi
}

build_to_be_cleaned_log() {
  local source_log_file="${SOURCE_LOG_FILE}"
  local output_log_file="${OUTPUT_LOG_FILE}"
  local excluded_user_id_pattern_local="${EXCLUDED_USER_ID_PATTERN}"

  if [ ! -f "${source_log_file}" ]; then
    echo "Missing source log: ${source_log_file}"
    return 1
  fi

  if [ -n "${excluded_user_id_pattern_local}" ]; then
    grep -Ev "${excluded_user_id_pattern_local}" "${source_log_file}" > "${output_log_file}"
  else
    cp "${source_log_file}" "${output_log_file}"
  fi
  echo "Created filtered cleanup file: ${output_log_file}"
}

calculate_cleanup_size_from_log() {
  local cleanup_log_file="${CLEANUP_LOG_FILE}"
  local cleanup_dry_run_local="${CLEANUP_DRY_RUN}"

  if [ -f "${cleanup_log_file}" ] && [ -s "${cleanup_log_file}" ]; then
    TOTAL_KB=$(awk '{sum+=$1} END {print sum}' "${cleanup_log_file}")
    if [ -n "${TOTAL_KB}" ] && [ "${TOTAL_KB}" -gt 0 ] 2>/dev/null; then
      TOTAL_MIB=$((TOTAL_KB / 1024))
      if [ "${cleanup_dry_run_local}" = "false" ]; then
        echo "Cleanup summary: freed approximately ${TOTAL_MIB} MiB (${TOTAL_KB} KiB) of disk space. Details in ${cleanup_log_file}."
      else
        echo "Cleanup summary (dry run): would free approximately ${TOTAL_MIB} MiB (${TOTAL_KB} KiB) of disk space. Details in ${cleanup_log_file}."
      fi
    else
      echo "Cleanup summary: no size information could be calculated from ${cleanup_log_file}."
    fi
  else
    echo "Cleanup summary: no cleanup size information recorded; ${cleanup_log_file} does not exist or is empty."
  fi
}

# Planned step 2 extension: consume filtered log to actually remove entries.
apply_cleanup_from_log() {
  local cleanup_log_file="${CLEANUP_LOG_FILE}"
  local cleanup_dry_run_local="${CLEANUP_DRY_RUN}"
  if [ "${cleanup_dry_run_local}" = "false" ]; then
    echo "TODO step 2: implement path parsing/removal using ${cleanup_log_file}"
  fi
}

#################
# MAIN
#################

echo Cleaning caches
EXCLUDED_USER_ID_PATTERN="$(
  kubectl get pod --all-namespaces \
  | egrep ' intellij-desktop' \
  | awk '{print $1}' \
  | while read NS; do kubectl -n $NS exec deploy/intellij-desktop -- bash -c 'echo $USER_ID'; done \
  | egrep -v '^[0-9]+$' | tr '\n' '|' | sed 's_|$__'
)"

if [ "${UPDATE_CLEANUP_DU_LOG_LATEST}" = "true" ]; then
  # Main flow always regenerates the latest log in dry-run mode when requested.
  UPDATE_CLEANUP_DU_LOG_LATEST="${UPDATE_CLEANUP_DU_LOG_LATEST}" \
  CLEANUP_DRY_RUN="true" \
    run_cleanup_scan
else
  echo "Skipping scan because UPDATE_CLEANUP_DU_LOG_LATEST=${UPDATE_CLEANUP_DU_LOG_LATEST}; using existing ${CLEANUP_DU_LOG_LATEST}"
fi

SOURCE_LOG_FILE="${CLEANUP_DU_LOG_LATEST}" \
OUTPUT_LOG_FILE="${TO_BE_CLEANED}" \
EXCLUDED_USER_ID_PATTERN="${EXCLUDED_USER_ID_PATTERN}" \
  build_to_be_cleaned_log || exit 1

CLEANUP_LOG_FILE="${TO_BE_CLEANED}" \
CLEANUP_DRY_RUN="true" \
  calculate_cleanup_size_from_log