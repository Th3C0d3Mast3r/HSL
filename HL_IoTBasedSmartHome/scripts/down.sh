#!/usr/bin/env bash
set -e

COMPOSE_DIR="$(dirname "$0")/../docker"
COMPOSE_FILES=("-f" "$COMPOSE_DIR/compose.yml")

show_help() {
  echo "Usage: ./scripts/down.sh [OPTIONS]"
  echo "Options:"
  echo "  --all              Stop all service modules"
  echo "  --type 1           Stop Preset 1 (IoT Stack)"
  echo "  --type 2           Stop Preset 2 (Media & Cloud)"
  echo "  --type 3           Stop Preset 3 (Monitoring & Utilities)"
  echo "  --iot              Stop IoT module"
  echo "  --media            Stop Media module"
  echo "  --cloud            Stop Cloud module"
  echo "  --monitoring       Stop Monitoring module"
  echo "  --utilities        Stop Utilities module"
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
        1) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.iot.yml") ;;
        2) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.media.yml") COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.cloud.yml") ;;
        3) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.monitoring.yml") COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.utilities.yml") ;;
        *) echo "Unknown type: $2"; exit 1 ;;
      esac
      shift 2
      ;;
    --iot) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.iot.yml"); shift ;;
    --media) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.media.yml"); shift ;;
    --cloud) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.cloud.yml"); shift ;;
    --monitoring) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.monitoring.yml"); shift ;;
    --utilities) COMPOSE_FILES+=("-f" "$COMPOSE_DIR/compose.utilities.yml"); shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "Stopping specified Docker containers..."
docker compose "${COMPOSE_FILES[@]}" down