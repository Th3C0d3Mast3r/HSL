#!/usr/bin/env bash
set -e

ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Error: .env file missing."
  exit 1
fi

BACKUP_DIR="${BACKUP_ROOT:-/mnt/storage/backups}"
DATA_DIR="${DATA_ROOT:-/srv/homelab/appdata}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/homelab_appdata_${TIMESTAMP}.tar.gz"

echo "========================================"
echo "       HOMELAB BACKUP PROCESS          "
echo "========================================"

mkdir -p "$BACKUP_DIR"

echo "[+] Archiving configuration data from $DATA_DIR..."
tar -czf "$BACKUP_FILE" -C "$DATA_DIR" .

echo "[+] Pruning backups older than 14 days..."
find "$BACKUP_DIR" -name "homelab_appdata_*.tar.gz" -mtime +14 -delete

echo "[✓] Backup archive created: $BACKUP_FILE"