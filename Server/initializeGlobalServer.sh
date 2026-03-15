#!/bin/bash
set -e
echo "==========================="
echo "INITIALIZING GLOBAL SERVER"
echo "==========================="

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run with sudo privilege"
    echo "[!] sudo ./initializeGlobalServer.sh"
    exit 1
fi

# ─────────────────────────────────────────
# TAILSCALE
# ─────────────────────────────────────────
if ! command -v tailscale > /dev/null 2>&1; then
    echo "[+] INSTALLING TAILSCALE"
    curl -fsSL https://tailscale.com/install.sh | sh
fi

systemctl enable tailscaled
systemctl restart tailscaled

if ! tailscale status > /dev/null 2>&1; then
    echo "[+] Tailscale login required"
    tailscale up
fi

TAILSCALE_IP=$(tailscale ip -4)

if [ -z "$TAILSCALE_IP" ]; then
    echo "[!] ERROR: Could not get Tailscale IP. Is Tailscale connected?"
    exit 1
fi

echo "[✓] TAILSCALE IP: $TAILSCALE_IP"

# ─────────────────────────────────────────
# NEXTCLOUD
# ─────────────────────────────────────────
echo ""
echo "[+] CHECKING NEXTCLOUD..."

if ! snap list | grep -q nextcloud; then
    echo "[!] ERROR: NextCloud snap not found. Please install it first."
    exit 1
fi

snap start nextcloud
sleep 5

# Verify initialized
echo "[+] Verifying NextCloud is initialized..."
if ! nextcloud.occ status 2>/dev/null | grep -q "installed: true"; then
    echo "[!] ERROR: NextCloud not initialized. Complete setup at http://192.168.31.252 first."
    exit 1
fi
echo "[✓] NextCloud is initialized."

# Configure trusted domains
echo "[+] Configuring trusted domains for Tailscale..."
nextcloud.occ config:system:set trusted_domains 1 --value="$TAILSCALE_IP"
nextcloud.occ config:system:set overwritehost --value="$TAILSCALE_IP"
nextcloud.occ config:system:set overwriteprotocol --value="http"
nextcloud.occ config:system:set overwrite.cli.url --value="http://$TAILSCALE_IP"
echo "[✓] Trusted domains configured."

# Firewall
if command -v ufw > /dev/null 2>&1 && ufw status | grep -q "Status: active"; then
    echo "[+] UFW detected — opening port 80..."
    ufw allow 80/tcp
    echo "[✓] Port 80 opened."
fi

# ─────────────────────────────────────────
# FINAL OUTPUT
# ─────────────────────────────────────────
echo ""
echo "================================================"
echo "✅ GLOBAL SERVER IS ACTIVE"
echo "================================================"
echo "  TAILSCALE IP  : $TAILSCALE_IP"
echo "  NEXTCLOUD URL : http://$TAILSCALE_IP"
echo ""
echo "  Open the above URL from any device on"
echo "  your Tailscale network, anywhere in the world."
echo "================================================"