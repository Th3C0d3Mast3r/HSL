# HL_IoTBasedSmartHome
This is the `v2` that I am making for my Home. The main aim of this is that, I can use the Server, along with my Pi  Zero *(the PI Hole for the LAN)*; and along with that, the server will be running things that would be modular- so, user can customize what all he wants to have on the server *(and if, in future reqs change, can add on more things!)*

So, this HL will have the following things *(along with some more, which I will add as I make and refine this)*.
- Telemetry for Containers and Services running on the server.
- Status of Pi Zero and Router
- MQTT Server running to which other IoT devices can connect.
- Jellyfin, NextCloud and Samba for LAN based media access *(along with TailScale)*
- Home Assistant for home automation, integrated with ESP32 / custom IoT sensors over MQTT.
- Frigate NVR for camera feeds *(ESP32-CAM and compatible RTSP cameras)*
- Centralized logging for all containers *(Loki + Promtail → Grafana)*
- Automated daily backups of application data

## ARCHITECTURE
The following is the architecture of the current server-
![HL IoT-Based Smart Home Architecture](assets/HL_IoTBasedSmartHome.png)

---

## GETTING STARTED

> [!NOTE] 
> End-to-end provisioning & deployment guide for a new Ubuntu host.

### Step 1: Clone Repository & Access Root Directory

```bash
git clone https://github.com/your-username/HL-IoTBasedSmartHome.git
cd HL-IoTBasedSmartHome
```

### Step 2: Initialize Configuration & Inventory Files

```bash
# Copy template environment file to local untracked file
cp .env.example .env

# Copy template inventory file to local Ansible inventory
cp ansible/inventory/hosts.example.yml ansible/inventory/hosts.yml
```

> [!TIP]
> **(Optional)** Edit values in `.env` based on ur preferences


### Step 3: Install Host Prerequisites

```bash
sudo apt update -y
sudo apt install -y ansible
```

### Step 4: Execute Ansible Host Setup Playbooks

```bash
# 1. Initialize host directory hierarchy (/srv/homelab/appdata and /mnt/storage)
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/storage.yml -K

# 2. Install Docker Engine, Docker Compose plugin, and configure user permissions
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/server.yml -K

# 3. Configure UFW firewall rules, Tailscale VPN, and Samba local file shares
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/networking.yml -K

# 4. Configure automated daily backup cron schedules
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/backup.yml -K
```

### Step 5: Apply Group Membership & Set Script Permissions

```bash
# Enable Docker group access without requiring a system reboot
newgrp docker

# Ensure management scripts have execution privileges
chmod +x scripts/*.sh
```

### Step 6: Deploy Application Container Stacks

```bash
# Option A: Start ALL service modules simultaneously
./scripts/up.sh --all

# Option B: Start by preset profile
./scripts/up.sh --type 1   # IoT Stack (Mosquitto + Home Assistant)
./scripts/up.sh --type 2   # Media & Cloud (Jellyfin + Nextcloud)
./scripts/up.sh --type 3   # Observability & Utilities (Prometheus + Grafana + Dozzle + Uptime Kuma)

# Option C: Deploy a custom combination
./scripts/up.sh --iot --monitoring
```

### Step 7: Verify System Operational Health

```bash
./scripts/health.sh
```
