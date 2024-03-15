# run as user...
if ! mount | grep -q /mnt/u380503.your-storagebox.de; then
  echo "ERROR: /mnt/u380503.your-storagebox.de missing in mount list. Trying to re-mount..."
  mount /mnt/u380503.your-storagebox.de \
    && echo "INFO: /mnt/u380503.your-storagebox.de was successfully re-mounted" \
    || echo "ERROR: Could not re-mount /mnt/u380503.your-storagebox.de"
fi

