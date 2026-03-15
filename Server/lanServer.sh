#!/bin/bash

set -e

echo "======================================="
echo " Initializing LAN Server (Samba)"
echo "======================================="

if [ "$EUID" -ne 0 ]; then
  echo "Run with sudo:"
  echo "sudo ./lanServer.sh"
  exit 1
fi

USER_NAME="oobantu"
SAMBA_ROOT="/home/oobantu/samba"
SMB_CONF="/etc/samba/smb.conf"

# ---- Install Samba if missing ----
if ! command -v smbd >/dev/null 2>&1; then
  echo "[+] Installing Samba..."
  apt update -y >/dev/null
  apt install samba -y
fi

# ---- Validate directories ----
for dir in photos videos; do
  if [ ! -d "$SAMBA_ROOT/$dir" ]; then
    echo "❌ Directory missing: $SAMBA_ROOT/$dir"
    exit 1
  fi
done

# ---- Configure Samba (only once) ----
if ! grep -q "\[photos\]" "$SMB_CONF"; then
  echo "[+] Adding Samba shares..."

  cat <<EOF >> "$SMB_CONF"

[photos]
   path=$SAMBA_ROOT/photos
   browseable=yes
   writable=yes
   valid users=$USER_NAME
   create mask=0664
   directory mask=0775

[videos]
   path=$SAMBA_ROOT/videos
   browseable=yes
   writable=yes
   valid users=$USER_NAME
   create mask=0664
   directory mask=0775
EOF
fi

# ---- Ensure Samba password exists ----
if ! pdbedit -L | grep -q "^$USER_NAME:"; then
  echo "[+] Setting Samba password for $USER_NAME"
  smbpasswd -a "$USER_NAME"
fi

# ---- Start Samba ----
systemctl enable smbd
systemctl restart smbd

LAN_IP=$(ip route get 1 | awk '{print $7;exit}')

echo
echo "======================================="
echo " ✅ LAN SERVER ACTIVE"
echo "======================================="
echo " 🏠 LAN IP        : $LAN_IP"
echo " 📁 Photos Share : \\\\$LAN_IP\\photos"
echo " 🎥 Videos Share : \\\\$LAN_IP\\videos"
echo "======================================="
