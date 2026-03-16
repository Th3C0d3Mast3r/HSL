![Linux](https://img.shields.io/badge/Kernel-Linux-white?logo=linux&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Preferred_OS-Ubuntu-orange?logo=ubuntu&logoColor=white)

# HS_1 - Tailscale and NextCloud Based
This is the directory/architecture which can be used for a simple home-server which can be switched-on and switched-off; allowing power save along with the HOME CLOUD feature. For the same, the architecture allows for the following things:-

- `LAN SERVER`: Using samba, we can have a JUST LAN BASED storage
- `TAILSCALE + NEXTCLOUD`: Using the homeserver OFF-LAN. This is done via the Tailscale giving VPNized IP connection to access. 

Thus, the following architecture allows to use the architecture as PURE LAN, or, WORK FOR OFF LAN as well; with the flexibility of switching on, or switching off.

--- 

## HOME SERVER SPECS
| SERVICE[S]     | DESCRIPTION        |
|----------------|--------------------|
| OS             | Ubuntu LTS         |
| Laptop         | HP Laptop          |
| Processor      | i3-5th Gen         |
| Wi-Fi          | Hotspot / Router   |
| Battery        | Only when charging |
| RAM            | 8GB                |
| Storage        | 1TB Hard Disk      |

The above specs are the one that I am running my homeserver on-and am sure, anything with higher specs *(assumingly, some lower as well)*, **SHOULD WORK**-with the only difference of performance and speed being delayed. 

---

## ARCHITECTURE
The following is the home-server architecture, how it works. Do check the below shcematic out:
![image](./assets/architecture.png)

---

## HOW TO USE (SETTING UP)
The following architecture is a quick-build, a plug-and-play on Ubuntu. So, for the same, here are the following logic of the commands:-
- `./initializeGlobalServer.sh`: This would **start** tailscale, and nextcloud. For tailscale, the first launch, you would have to configure your overall tailscale account. Will attach a link for the same below
- `./downGlobalServer.sh`: This would **stop** tailscale and nextcloud- making it offline and unreachable OFF-LAN
- `./lanServer.sh`: This would start the **SAMBA SERVICE** and allow the lan access to the server, using the samba port
- `./lanDown.sh`: This would stop the **SAMBA SERVICE** and stop the lan access to the server.
> ⚠️**NOTE**: The shell scripts are written to work for Ubuntu and `apt` package manager. In order to use some different Distro of the OS- change the package manager in the above shell scripts.

---

## SOURCES
The following are the sources which can be viewed to understand the architecture, and understand, how this thing WORKS inherently:-

---

## MISCELLANEOUS
**CONTRIBUTED BY:** Th3C0d3Mast3r
<!-- HSL_DESCRIPTOR: A Simple Samba+Tailscale+NextCloud based on-demand home server-->

> **HSL** | Created and maintained by **@Th3C0d3Mast3r** and other contributors.
