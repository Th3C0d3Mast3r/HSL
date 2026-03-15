#!/bin/bash

set -e

echo "======================================="
echo " Shutting Down LAN Server"
echo "======================================="

if [ "$EUID" -ne 0 ]; then
  echo "Run with sudo:"
  echo "sudo ./lanDown.sh"
  exit 1
fi

echo "[+] Stopping Samba..."
systemctl stop smbd || true

echo
echo "======================================="
echo " ✅ LAN SERVER STOPPED"
echo "======================================="