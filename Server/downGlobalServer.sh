#!/bin/bash
set -e
echo "======================================="
echo "⚠️  Shutting Down GLOBAL Server"
echo "======================================="

if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo:"
    echo "sudo ./downGlobalServer.sh"
    exit 1
fi

echo "[!] Stopping NextCloud..."
snap stop nextcloud || true
echo "[✓] NextCloud stopped."

echo "[!] Bringing Tailscale down..."
tailscale down || true
echo "[✓] Tailscale disconnected."

echo ""
echo "======================================="
echo "✅ GLOBAL SERVER STOPPED"
echo "======================================="
echo "  NextCloud : offline"
echo "  Tailscale : disconnected"
echo "======================================="