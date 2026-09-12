#!/usr/bin/env bash
set -e

echo "========================================"
echo "    HOMELAB SYSTEM HEALTH REPORT        "
echo "========================================"
echo ""

echo "--- Storage Mount Status ---"
df -h /srv/homelab/appdata /mnt/storage/* 2>/dev/null || df -h /
echo ""

echo "--- Running Docker Containers ---"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "--- Core Port Listeners ---"
PORTS=(1883 3000 8096 8123 9090 8888 3001)
for port in "${PORTS[@]}"; do
  if ss -tuln | grep -q ":${port} "; then
    echo "Port ${port}: ACTIVE"
  else
    echo "Port ${port}: INACTIVE"
  fi
done
echo ""