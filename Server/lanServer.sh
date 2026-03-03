# ! /bin/bash
set -e

RED="\e[31m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

echo -e "${CYAN}Checking for Pre-Reqs${RESET}"
if [ "$EUID" -ne 0 ]; then
    echo -e "[!]${RED}Missing: sudo${RESET}"
    echo -e "[!]${RED}Run with the sudo command${RESET}"
    exit 1
fi

echo -e "${BLUE}Enter the Username: ${RESET}"
read USERNAME

echo -e "${BLUE}Enter the samba root [absolute location]: ${RESET}"
read SAMBA_ROOT

SMB_CONF="/etc/samba/samba.conf"

# NOW WE CHECK FOR THE SAMBA INSTALLED OR NO
if ! command -v smbd > /dev/null 2>&1; then
    echo -e "[+]${BLUE}INSTALLING SAMBA${RESET}"
    apt update -y >/dev/null
    apt install samba
    echo -e "[#]${GREEN}SAMBA INSTALLED${RESET}"
fi

# CHECK FOR THE DIRECTORIES AND STUFF
for dir in photos videos; do
    if [ ! -d "$SAMBA_ROOT/$dir" ]; then
        echo -e "[!]${RED}DIRECTORIES MISSING- EXITING${RESET}"
        exit 1
    fi
done


# the below are the samba configurations, THESE NEED TO BE CONFIGURED JUST ONCE
echo -e "[+]${BLUE}WRITING SAMBA CONFIGS${RESET}"
if ! grep -q "\[photos\]" "$SMB_CONF"; then
    cat <<EOF>> "$SMB_CONF"

[photos]
    path=$SAMBA_ROOT/photos
    browseable=yes
    writable=yes
    valid users=$USERNAME
    create mask=0664
    directory mask=0775
[videos]
    path=$SAMBA_ROOT/videos
    browseable=yes
    writable=yes
    valid users=$USERNAME
    create mask=0664
    directory mask=0775
EOF
fi

echo -e "[#]${GREEN}CONFIGS DONE${RESET}"


if ! pdbedit -L | grep -q "^$USERNAME:"; then
    echo -e "Setting the password for $USERNAME"
    smbpasswd -a "$USERNAME"
fi

systemctl enable smbd
systemctl restart smbd
systemctl status smbd

LAN_IP=$(ip route get 1 | awk '{print $7;exit})

echo
echo -e "===================================================================="
echo -e "${GREEN}SERVER ACTIVE AND RUNNING${RESET}"
echo -e "${BLUE}LAN IP: ${RESET} $LAN_IP"
echo -e "${BLUE}PHOTOS LOCATION: ${RESET} \\\\$LAN_IP"\\photos"
echo -e "${BLUE}VIDEOS LOCATION: ${RESET} \\\\$LAN_IP"\\videos"
echo -e "===================================================================="