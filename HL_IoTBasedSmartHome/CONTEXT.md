# Project Development Context

## Project Goal

This repository is an open-source, modular HomeLab / IoT-based Smart Home reference implementation.

The project is designed to run on a home server (currently a Linux-based laptop/server) and provide a combination of:

- Media services
- Personal cloud/file services
- Custom IoT infrastructure
- ESP32 / ESP32-CAM device support
- Server and network monitoring
- Centralized logging
- Backups
- Remote access
- Lightweight operational utilities

The repository must not be treated as a configuration dump for one specific physical machine.

It should instead be designed as a **reusable and reproducible HomeLab framework** that another person can clone, configure for their own environment, and deploy with minimal modification.

---

## High-Level Architecture

The architecture is intentionally divided into a few major boundaries:

```text
                         INTERNET
                            |
                            v
                     +-------------+
                     |    ROUTER   |
                     +------+------+
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
          Pi-hole      HOME SERVER     IoT DEVICES
                       (Linux Host)         |
                            |               |
                 +----------+----------+    |
                 |          |          |    |
                 v          v          v    v
              SERVICES   MONITORING  STORAGE
                 |
        +--------+--------+
        |        |        |
      Media    Cloud      IoT
        |        |        |
     Jellyfin Nextcloud  MQTT
                           |
                    Home Assistant
                           |
                        Sensors
````

 The actual architecture diagram is maintained in:

```
assets/HL_IoTBasedSmartHome.png
```

 The HLD should remain intentionally simple.

 Implementation-specific details such as Docker networking, ports, exporters, container names, database internals, mount paths, environment variables, and host-specific configuration belong in the documentation and implementation files rather than the HLD.

---

 # Design Principles

 ## 1\. Modular by Default

 Every major capability should be independently enableable.

 A user may want:

 - Only Jellyfin
- Jellyfin + Nextcloud
- Media + Cloud + Monitoring
- IoT + MQTT + Home Assistant
- Cameras without the rest of the IoT stack
- The complete stack

 The repository must therefore avoid assuming that every user wants every service.

 Services should be grouped into logical modules such as:

 - Media
- Cloud
- IoT
- Cameras
- Monitoring
- Logging
- Utilities
- Backup

 Adding or removing a module should not require rewriting the entire deployment.

---

 ## 2\. Separate Host Configuration from Applications

 The project uses two primary automation layers.

 ### Ansible

 Ansible is responsible for preparing and configuring the host machine.

 Examples include:

 - Linux package installation
- User and group management
- SSH configuration
- Firewall configuration
- Storage preparation
- Filesystem mounts
- Samba configuration
- Tailscale installation/configuration
- Docker installation
- Host-level monitoring requirements
- Backup prerequisites
- System-level directories and permissions

 Ansible should be written with **idempotency** as a core requirement.

 Running an Ansible playbook multiple times should converge the machine toward the desired state without unnecessarily modifying or breaking an already-correct configuration.

 ### Docker Compose

 Docker Compose is responsible for application workloads.

 Examples include:

 - Jellyfin
- Nextcloud
- Mosquitto
- Home Assistant
- InfluxDB
- Frigate
- Prometheus
- Grafana
- Loki
- Uptime Kuma
- Other containerized applications

 Do not unnecessarily use Ansible to manage the internal configuration of every container.

 The intended separation is:

```
Ansible
    |
    +-- Prepare the machine
    +-- Configure the host
    +-- Prepare storage
    +-- Install required host software
    +-- Configure host-level services
    |
    v
Docker / Docker Compose
    |
    +-- Run applications
    +-- Manage application containers
    +-- Manage application networks
    +-- Manage application dependencies
```

---

 # Repository Structure

 The repository should follow this general structure:

```
HL-IoTBasedSmartHome/
│
├── README.md
├── CONTEXT.md
├── LICENSE
├── .gitignore
├── .env.example
│
├── assets/
│   └── HL_IoTBasedSmartHome.png
│
├── ansible/
│   ├── ansible.cfg
│   ├── requirements.yml
│   │
│   ├── inventory/
│   │   └── hosts.example.yml
│   │
│   ├── group_vars/
│   │   └── all/
│   │       └── main.yml
│   │
│   ├── host_vars/
│   │   └── .gitkeep
│   │
│   ├── playbooks/
│   │   ├── bootstrap.yml
│   │   ├── server.yml
│   │   ├── storage.yml
│   │   ├── networking.yml
│   │   └── backup.yml
│   │
│   └── roles/
│       ├── common/
│       ├── docker/
│       ├── storage/
│       ├── samba/
│       ├── tailscale/
│       ├── firewall/
│       └── backup/
│
├── docker/
│   ├── compose.yml
│   ├── compose.media.yml
│   ├── compose.cloud.yml
│   ├── compose.iot.yml
│   ├── compose.cameras.yml
│   ├── compose.monitoring.yml
│   ├── compose.logging.yml
│   ├── compose.utilities.yml
│   │
│   ├── .env.example
│   │
│   ├── media/
│   ├── cloud/
│   ├── iot/
│   ├── cameras/
│   ├── monitoring/
│   ├── logging/
│   └── utilities/
│
├── configs/
│   ├── prometheus/
│   ├── grafana/
│   ├── mosquitto/
│   ├── frigate/
│   ├── homeassistant/
│   └── samba/
│
├── scripts/
│   ├── up.sh
│   ├── down.sh
│   ├── update.sh
│   ├── backup.sh
│   └── health.sh
│
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   ├── storage.md
│   ├── networking.md
│   ├── backups.md
│   └── troubleshooting.md
│
└── secrets/
    └── .gitkeep
```

 This structure is a guideline rather than an absolute requirement.

 If a simpler or more maintainable structure is discovered during implementation, prefer the simpler structure and update this document accordingly.

---

 # Configuration and Secrets

 This repository is intended to be publicly available on GitHub.

 ## NEVER commit sensitive or environment-specific information.

 The following must never appear in tracked files:

 - Passwords
- API keys
- Access tokens
- Private keys
- SSH private keys
- Tailscale authentication keys
- MQTT credentials
- Database passwords
- Nextcloud secrets
- Grafana credentials
- Cloud credentials
- Personal email addresses where avoidable
- Personal usernames where avoidable
- Public IP addresses
- Private IP addresses from the author's home network
- MAC addresses
- Hostnames that identify the author's actual network
- Internal DNS names
- Wi-Fi SSIDs
- Wi-Fi passwords
- Router credentials
- VPN credentials
- Personally identifiable information
- Camera URLs
- Camera credentials
- Device-specific secrets
- Real filesystem paths that expose the author's machine layout
- Any other information that could identify, access, or compromise the author's infrastructure

 ### Ports

 Do not document real-world port mappings belonging to the author's personal deployment unless the port is genuinely part of the application's documented default configuration and presenting it does not expose private infrastructure.

 When documenting examples, prefer placeholders:

```
<HTTP_PORT>
<HTTPS_PORT>
<MQTT_PORT>
<GRAFANA_PORT>
<SERVER_IP>
<ROUTER_IP>
```

 or clearly fictional/example values.

 Never expose the author's actual port-forwarding configuration.

 The README should describe **what a service does**, not reveal how the author's personal network is exposed to the Internet.

---

 # Public Repository Safety

 Before every commit or pull request, verify that no sensitive information has been introduced.

 Particular attention should be given to:

 - `.env` files
- Ansible inventory files
- Ansible Vault files
- SSH configuration
- Docker Compose files
- Docker environment files
- Grafana configuration
- MQTT configuration
- Frigate configuration
- Home Assistant configuration
- Backup configuration
- Scripts containing hard-coded values

 Use example files whenever configuration is required.

 For example:

```
.env.example
hosts.example.yml
config.example.yml
```

 The example file should contain placeholders rather than real values.

 Example:

```
server_ip: "<SERVER_IP>"
domain: "<DOMAIN>"
mqtt_username: "<MQTT_USERNAME>"
```

 Never use the author's real values merely because they make the example easier to understand.

---

 # Environment-Specific Configuration

 The repository should distinguish between:

```
Repository Configuration
```

 and:

```
Machine-Specific Configuration
```

 Repository configuration includes:

 - Compose definitions
- Ansible roles
- Playbooks
- Service configuration templates
- Prometheus scrape configuration templates
- Grafana provisioning
- Mosquitto configuration templates
- Documentation
- Scripts

 Machine-specific configuration includes:

 - IP addresses
- Hostnames
- Storage paths
- Credentials
- Device IDs
- MAC addresses
- Hardware-specific settings
- Camera addresses
- Network-specific settings

 Machine-specific configuration should be supplied by the user through:

 - Ansible variables
- Ansible Vault
- Environment files
- Untracked local configuration
- Templates
- Other appropriate secret/configuration mechanisms

---

 # Idempotency

 All Ansible roles and playbooks must be designed to be idempotent.

 A user should be able to run:

```
ansible-playbook ...
```

 multiple times without causing:

 - Duplicate configuration entries
- Duplicate users
- Duplicate mounts
- Repeated package installation
- Broken services
- Unnecessary restarts
- Destructive changes

 Prefer Ansible modules over shell commands whenever an appropriate module exists.

 Avoid constructs such as:

```
ansible.builtin.shell: ...
```

 unless there is a clear reason that an Ansible module cannot perform the required operation.

 When shell commands are unavoidable, make them safe to repeat and use appropriate change detection.

---

 # Docker Compose Principles

 Docker Compose configurations should be:

 - Modular
- Reproducible
- Readable
- Version-controlled
- Easy to understand
- Easy to start/stop independently where practical

 Do not hard-code secrets into Compose files.

 Use environment variables or appropriate secret mechanisms.

 Persistent application data should live outside the Git repository.

 The repository should contain configuration required to recreate the service, but not runtime state.

 Do not commit:

```
database/
data/
logs/
cache/
media/
backups/
```

 or equivalent runtime directories.

---

 # Application Modules

 The initial application modules are:

 ## Media

 - Jellyfin

 ## Cloud

 - Nextcloud

 ## IoT

 - Mosquitto MQTT
- Home Assistant
- InfluxDB
- Node-RED, if required

 ## Cameras

 - Frigate

 ## Monitoring

 - Prometheus
- Grafana

 Supporting components may include:

 - cAdvisor
- Node Exporter
- SNMP Exporter
- Alertmanager

 ## Logging

 - Fluent Bit
- Loki

 ## Utilities

 - Uptime Kuma
- Dozzle

 ## Backup

 - Restic or another suitable backup solution

 The exact service list may evolve as the project develops.

 New services should only be added when they provide a clear benefit and do not unnecessarily increase complexity.

---

 # Observability

 Observability is a first-class component of the project.

 The monitoring architecture should cover:

```
Host
  |
  +-- Node Exporter
  |
  v
Prometheus
  |
  v
Grafana
```

 Container-level metrics may be collected through cAdvisor.

 Router/network metrics may be collected through SNMP and an SNMP exporter.

 Application logs should be handled separately from metrics:

```
Containers
    |
    v
Fluent Bit
    |
    v
Loki
    |
    v
Grafana
```

 Monitoring should observe the infrastructure without becoming an unnecessary dependency of the applications being monitored.

---

 # IoT Architecture

 The IoT system is primarily designed around custom devices rather than commercial smart-home products.

 Primary devices include:

 - ESP32 devices
- ESP32-CAM devices
- Custom water sensors
- Environmental sensors
- Other custom sensor nodes

 MQTT is the primary messaging layer for sensor telemetry and device communication.

 Conceptually:

```
ESP32 / Sensors
       |
       v
     MQTT
       |
       +------> Home Assistant
       |
       +------> InfluxDB
       |
       +------> Other consumers
```

 Camera workloads are treated separately:

```
ESP32-CAM
    |
    v
  Frigate
    |
    +----> Camera recordings
    |
    +----> Events
              |
              v
        Home Assistant / MQTT
```

---

 # Remote Access

 Tailscale is intended to provide secure remote access to services without unnecessarily exposing services directly to the public Internet.

 The project should prefer:

```
Internet
    |
    v
Tailscale
    |
    v
Home Server
```

 over exposing individual application services directly through router port forwarding.

 Any documentation discussing remote access should avoid revealing the author's actual public endpoint, IP address, domain, or firewall configuration.

---

 # Storage

 Storage should be treated as a separate concern from applications.

 Applications consume storage, but they should not dictate the host's physical storage layout.

 The project should support configurable locations for:

 - Application data
- Media
- User files
- Camera recordings
- Databases
- Backups

 Storage paths must be configurable and must not assume the author's actual filesystem layout.

 Example:

```
<DATA_ROOT>
<MEDIA_ROOT>
<BACKUP_ROOT>
<CAMERA_ROOT>
```

 Do not hard-code paths such as:

```
/home/<username>/...
/mnt/<personal-disk-name>/...
```

 in reusable configuration.

---

 # Backups

 Backups are separate from replication.

 The project should define what needs to be backed up, rather than simply backing up every Docker volume.

 Important configuration and application data may include:

 - Nextcloud data/configuration
- Home Assistant configuration
- MQTT configuration
- Frigate configuration
- Grafana configuration
- Prometheus configuration
- Other critical application state

 Large or reproducible data such as media should not automatically be treated as backup data unless explicitly configured.

 The backup strategy should support configurable local and/or off-site destinations.

---

 # Documentation Principles

 Documentation should be written for someone who has never seen the author's server.

 It should explain:

 1. What the project is
2. What services are available
3. What each service does
4. Which modules are optional
5. Prerequisites
6. Host preparation
7. Configuration
8. Deployment
9. Updating
10. Backups
11. Troubleshooting
12. Security considerations

 Avoid documentation that assumes:

 - The reader has the author's network
- The reader has the author's hardware
- The reader knows the author's IP addresses
- The reader knows the author's directory structure
- The reader has the author's credentials
- The reader has the same IoT devices

---

 # Scripts

 Shell scripts should remain small convenience wrappers.

 They may provide commands such as:

```
./scripts/up.sh
./scripts/down.sh
./scripts/update.sh
./scripts/backup.sh
./scripts/health.sh
```

 Scripts should not become a second configuration-management system.

 Host configuration belongs in Ansible.

 Application deployment belongs in Docker Compose.

---

 # Contribution Guidelines

 Contributors should prefer:

 - Simple solutions
- Idempotent automation
- Modular services
- Configuration through variables
- Documented defaults
- Secure-by-default behavior
- Reproducible deployments
- Minimal host dependencies
- Containerized applications where appropriate

 Avoid:

 - Hard-coded personal configuration
- Hard-coded IP addresses
- Hard-coded credentials
- Unnecessary shell scripts
- Unnecessary services
- Over-engineering
- Vendor-specific assumptions
- Making optional components mandatory

 Every new service should answer:

```
Why is this needed?
What problem does it solve?
Can it be optional?
Does it need to run on the host or in a container?
What persistent data does it require?
How is it monitored?
How is it backed up?
```

---

 # Definition of Done

 A service/module should not be considered complete until:

 - It has a clear purpose.
- It is appropriately modular.
- It has documented prerequisites.
- Its configuration is reproducible.
- Secrets are not committed.
- Host-level requirements are handled through Ansible where appropriate.
- Application deployment is handled through Docker Compose where appropriate.
- Persistent data is separated from repository configuration.
- The service can be monitored where practical.
- Important configuration can be backed up.
- Documentation explains how to enable/disable it.
- The implementation does not expose the author's personal infrastructure.

---

 # Open Source Requirement

 This project is intended to be published publicly on GitHub.

 **Assume that every tracked file can be read by an unknown person.**

 Never rely on the repository being private.

 Before committing anything, ask:

 > "If this entire repository became public right now, could someone use it to identify, access, attack, or compromise the original author's home network or services?"

 If the answer is yes, remove or generalize the information.

 Use placeholders and examples instead.

 The repository should represent:

```
A reusable architecture
        +
A reproducible implementation
        +
Safe example configuration
```

 and never:

```
A copy of one person's private home infrastructure.
```

---

 # Future Scope

 Future versions may expand the project to support commercial and off-the-shelf smart-home devices in addition to the custom ESP32-based ecosystem.

 Potential V2 capabilities include:

 - Zigbee devices
- Z-Wave devices
- Matter devices
- Thread devices
- Commercial smart bulbs
- Smart switches
- Smart plugs
- Commercial environmental sensors
- Smart thermostats
- Energy monitoring
- Smart locks
- Additional home automation integrations
- Dedicated IoT VLAN/network segmentation
- More advanced network monitoring
- High-availability or multi-node deployments
- Additional backup targets
- Remote/off-site nodes

 These should remain optional and should not complicate the initial custom-ESP32-focused architecture.

 The V1 goal is to provide a **clean, lightweight, modular, secure, reproducible HomeLab + custom IoT platform**.

```

This gives your repo a pretty important rule: **the repository is the blueprint, not a snapshot of your house**. That distinction will save you a *lot* of trouble once you put it on GitHub.
```