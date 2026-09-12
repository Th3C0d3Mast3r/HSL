#!/usr/bin/env bash
set -e

ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

COMPOSE_DIR="$(dirname "$0")/../docker"

echo "========================================"
echo "       HOMELAB SYSTEM UPDATE           "
echo "========================================"

echo "[+] Pulling latest container images..."
docker compose -f "$COMPOSE_DIR/compose.yml" \
               -f "$COMPOSE_DIR/compose.iot.yml" \
               -f "$COMPOSE_DIR/compose.media.yml" \
               -f "$COMPOSE_DIR/compose.cloud.yml" \
               -f "$COMPOSE_DIR/compose.monitoring.yml" \
               -f "$COMPOSE_DIR/compose.logging.yml" \
               -f "$COMPOSE_DIR/compose.cameras.yml" \
               -f "$COMPOSE_DIR/compose.utilities.yml" pull

echo "[+] Recreating containers with updated images..."
docker compose -f "$COMPOSE_DIR/compose.yml" \
               -f "$COMPOSE_DIR/compose.iot.yml" \
               -f "$COMPOSE_DIR/compose.media.yml" \
               -f "$COMPOSE_DIR/compose.cloud.yml" \
               -f "$COMPOSE_DIR/compose.monitoring.yml" \
               -f "$COMPOSE_DIR/compose.logging.yml" \
               -f "$COMPOSE_DIR/compose.cameras.yml" \
               -f "$COMPOSE_DIR/compose.utilities.yml" up -d --remove-orphans

echo "[+] Pruning unused dangling images..."
docker image prune -f

echo "[✓] Homelab update completed."