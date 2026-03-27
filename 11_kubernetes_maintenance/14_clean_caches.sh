DRIVES_TO_BE_CLEANED="/mnt/u380503.your-storagebox.de/user-specific-shared-volumes"
CLEANUP_DRY_RUN=${CLEANUP_DRY_RUN:="true"}
UPDATE_CLEANUP_DU_LOG_LATEST=${UPDATE_CLEANUP_DU_LOG_LATEST:="true"}
TMP_DIR=/mnt/u380503.your-storagebox.de/tmp
CLEANUP_DU_LOG_LATEST="${TMP_DIR}/network_drive_cleanup_du_latest.log"
TO_BE_CLEANED="${TMP_DIR}/network_drive_cleanup_to_be_cleaned.log"
ENABLE_CLEANUP_DRIVE_GUARD=${ENABLE_CLEANUP_DRIVE_GUARD:="true"}

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
  local line=""
  local total_input_lines=0
  local excluded_lines=0
  local malformed_lines=0
  local missing_path_lines=0
  local kept_lines=0

  if [ ! -f "${source_log_file}" ]; then
    echo "Missing source log: ${source_log_file}"
    return 1
  fi

  : > "${output_log_file}"

  while IFS= read -r line || [ -n "${line}" ]; do
    total_input_lines=$((total_input_lines + 1))

    if [ -n "${excluded_user_id_pattern_local}" ] && printf '%s\n' "${line}" | grep -Eq "${excluded_user_id_pattern_local}"; then
      excluded_lines=$((excluded_lines + 1))
      continue
    fi

    if ! parse_cleanup_log_line "${line}"; then
      malformed_lines=$((malformed_lines + 1))
      continue
    fi

    if [ -e "${PARSED_PATH}" ]; then
      printf '%s\n' "${line}" >> "${output_log_file}"
      kept_lines=$((kept_lines + 1))
    else
      missing_path_lines=$((missing_path_lines + 1))
    fi
  done < "${source_log_file}"

  echo "Created filtered cleanup file: ${output_log_file}"
  echo "TO_BE_CLEANED filter summary: total=${total_input_lines}, excluded=${excluded_lines}, malformed=${malformed_lines}, missing=${missing_path_lines}, kept=${kept_lines}"
}

calculate_cleanup_size_from_log() {
  local cleanup_log_file="${CLEANUP_LOG_FILE}"
  local cleanup_dry_run_local="${CLEANUP_DRY_RUN}"

  if [ -f "${cleanup_log_file}" ] && [ -s "${cleanup_log_file}" ]; then
    TOTAL_KB=$(awk '{sum+=$1} END {print sum}' "${cleanup_log_file}")
    if [ -n "${TOTAL_KB}" ] && [ "${TOTAL_KB}" -gt 0 ] 2>/dev/null; then
      TOTAL_MIB=$((TOTAL_KB / 1024))
      TOTAL_GIB=$((TOTAL_MIB / 1024))
      if [ "${cleanup_dry_run_local}" = "false" ]; then
        echo "Cleanup summary: freed approximately ${TOTAL_GIB} GiB (${TOTAL_MIB} MiB or ${TOTAL_KB} KiB) of disk space. Details in ${cleanup_log_file}."
      else
        echo "Cleanup summary (dry run): would free  ${TOTAL_GIB} GiB (${TOTAL_MIB} MiB or ${TOTAL_KB} KiB) of disk space. Details in ${cleanup_log_file}."
      fi
    else
      echo "Cleanup summary: no size information could be calculated from ${cleanup_log_file}."
    fi
  else
    echo "Cleanup summary: no cleanup size information recorded; ${cleanup_log_file} does not exist or is empty."
  fi
}

parse_cleanup_log_line() {
  local cleanup_log_line="${1}"

  PARSED_SIZE_KB=""
  PARSED_PATH=""

  [ -z "${cleanup_log_line}" ] && return 1

  PARSED_SIZE_KB="${cleanup_log_line%%[[:space:]]*}"
  PARSED_PATH="${cleanup_log_line#${PARSED_SIZE_KB}}"
  PARSED_PATH="${PARSED_PATH#"${PARSED_PATH%%[![:space:]]*}"}"

  case "${PARSED_SIZE_KB}" in
    ''|*[!0-9]*)
      return 1
      ;;
  esac

  [ -z "${PARSED_PATH}" ] && return 1
  return 0
}

path_is_within_cleaned_drives() {
  local candidate_path="${1}"
  local drive=""

  for drive in ${DRIVES_TO_BE_CLEANED}; do
    case "${candidate_path}" in
      "${drive}"|"${drive}"/*)
        return 0
        ;;
    esac
  done
  return 1
}

apply_cleanup_from_log() {
  local cleanup_log_file="${CLEANUP_LOG_FILE}"
  local cleanup_dry_run_local="${CLEANUP_DRY_RUN}"
  local processed_entries=0
  local deleted_entries=0
  local missing_entries=0
  local failed_entries=0
  local malformed_entries=0
  local skipped_guard_entries=0
  local candidate_kb=0
  local deleted_kb=0
  local line=""

  if [ ! -f "${cleanup_log_file}" ] || [ ! -s "${cleanup_log_file}" ]; then
    echo "Cleanup apply: log file missing or empty: ${cleanup_log_file}"
    return 1
  fi

  while IFS= read -r line || [ -n "${line}" ]; do
    [ -z "${line}" ] && continue

    if ! parse_cleanup_log_line "${line}"; then
      malformed_entries=$((malformed_entries + 1))
      echo "Cleanup apply: skipping malformed log line: ${line}"
      continue
    fi

    processed_entries=$((processed_entries + 1))
    candidate_kb=$((candidate_kb + PARSED_SIZE_KB))

    if [ "${ENABLE_CLEANUP_DRIVE_GUARD}" = "true" ] && ! path_is_within_cleaned_drives "${PARSED_PATH}"; then
      skipped_guard_entries=$((skipped_guard_entries + 1))
      echo "Cleanup apply: skipped by drive guard: ${PARSED_PATH}"
      continue
    fi

    if [ ! -e "${PARSED_PATH}" ]; then
      missing_entries=$((missing_entries + 1))
      echo "Cleanup apply: already missing: ${PARSED_PATH}"
      continue
    fi

    if [ "${cleanup_dry_run_local}" = "true" ]; then
      echo "Cleanup apply (dry run): would remove ${PARSED_PATH} (${PARSED_SIZE_KB} KiB)"
      continue
    fi

    if [ -d "${PARSED_PATH}" ]; then
      if rm -rf -- "${PARSED_PATH}"; then
        deleted_entries=$((deleted_entries + 1))
        deleted_kb=$((deleted_kb + PARSED_SIZE_KB))
      else
        failed_entries=$((failed_entries + 1))
        echo "Cleanup apply: failed to remove directory: ${PARSED_PATH}"
      fi
    else
      if rm -f -- "${PARSED_PATH}"; then
        deleted_entries=$((deleted_entries + 1))
        deleted_kb=$((deleted_kb + PARSED_SIZE_KB))
      else
        failed_entries=$((failed_entries + 1))
        echo "Cleanup apply: failed to remove file: ${PARSED_PATH}"
      fi
    fi
  done < "${cleanup_log_file}"

  echo "Cleanup apply summary: processed=${processed_entries}, deleted=${deleted_entries}, missing=${missing_entries}, failed=${failed_entries}, malformed=${malformed_entries}, guard_skipped=${skipped_guard_entries}"
  if [ "${cleanup_dry_run_local}" = "false" ]; then
    echo "Cleanup apply summary: actually removed approximately $((deleted_kb / 1024)) MiB (${deleted_kb} KiB)."
  else
    echo "Cleanup apply summary (dry run): candidates approximately $((candidate_kb / 1024)) MiB (${candidate_kb} KiB)."
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
CLEANUP_DRY_RUN="${CLEANUP_DRY_RUN}" \
  apply_cleanup_from_log

CLEANUP_LOG_FILE="${TO_BE_CLEANED}" \
CLEANUP_DRY_RUN="${CLEANUP_DRY_RUN}" \
  calculate_cleanup_size_from_log