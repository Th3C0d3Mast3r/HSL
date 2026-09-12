# !/usr/bin/env bash

set -e

ENV_FILE="$(dirname "$0")/../.env"
if [ -f "$ENV_FILE" ]; then
  export $(grep -v '^#' "$ENV_FILE" | xargs)
else
  echo "Error: .env file not found. Create one from .env.example first."
  exit 1
fi

COMPOSE_DIR="$(dirname "$0")/../docker"
COMPOSE_FILES=("-f" "$COMPOSE_DIR/compose.yml")

show_help() {
  echo "Usage: ./scripts/up.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --all              Start all available modules"
  echo "  --type 1           Preset 1: IoT Stack (Mosquitto, Home Assistant)"
  echo "  --type 2           Preset 2: Media & Cloud (Jellyfin, Nextcloud)"
  echo "  --type 3           Preset 3: Monitoring & Utilities (Prometheus, Grafana, Dozzle, Uptime Kuma)"
  echo "  --iot              Include IoT module"
  echo "  --media            Include Media module"
  echo "  --cloud            Include Cloud module"
  echo "  --monitoring       Include Monitoring module"
  echo "  --utilities        Include Utilities module"
  echo "  --help             Display help"
}

if [ "$#" -eq 0 ]; then
  show_help
  exit 0
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --all)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.iot.yml")
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.media.yml")
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.cloud.yml")
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.monitoring.yml")
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.utilities.yml")
      shift
      ;;
    --type)
      case "$2" in
        1)
          COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.iot.yml")
          ;;
        2)
          COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.media.yml")
          COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.cloud.yml")
          ;;
        3)
          COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.monitoring.yml")
          COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.utilities.yml")
          ;;
        *)
          echo "Unknown type: $2. Options: 1, 2, 3"
          exit 1
          ;;
      esac
      shift 2
      ;;
    --iot)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.iot.yml")
      shift
      ;;
    --media)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.media.yml")
      shift
      ;;
    --cloud)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.cloud.yml")
      shift
      ;;
    --monitoring)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.monitoring.yml")
      shift
      ;;
    --utilities)
      COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.utilities.yml")
      shift
      ;;
    --help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

echo "Starting Docker containers with options..."
docker compose "${COMPOSE_FILES[@]}" up -d