# Contributing Guidelines

First off, thank you for considering contributing to this repository.

The primary goal behind creating this project is simple: **running your own home server should not feel difficult or intimidating**. While modern tools and LLMs have made things easier, many people still find server hardware, networking, and configurations overwhelming at first glance.

This repository exists to **simplify, document, and share practical home server and home lab architectures** so that anyone can build their own setup.

Contributions that improve clarity, add new architectures, enhance documentation, or introduce automation scripts are highly welcome.

---

# Contribution Rules

To maintain consistency and clarity across the repository, please follow these guidelines.

## 1. Unique Architectures
- Each directory **must represent a unique architecture**.
- Do not duplicate existing setups with minor variations.
- If your architecture is a modification or improvement of an existing one, clearly explain the differences.

---

## 2. Directory Naming Convention
All architectures must follow the naming structure below:
- **HS_<name>** → Home Servers  
- **HL_<name>** → Home Labs  

And the `<name>` must be in Camel-Case

Examples:
```
HS-basicMediaServer
HS-lowPowerNAS
HL-k8sLab
HL-selfHostedDevStack
```

---

## 3. Shell Scripts
If your setup includes automation:
- Place all shell scripts inside the directory.
- Ensure scripts are **readable, commented, and safe**.
- Avoid destructive commands unless clearly documented.

Example:

```
├── install.sh
├── setup-docker.sh
└── backup.sh
```

---

# Required Directory Structure
Each architecture directory **must include a `README.md`** that follows the structure below.

```
architecture-directory/
│
├── README.md
├── shell-scripts (optional)
└── assets/ (optional: diagrams, images)
```

---

# README.md Structure

Every architecture must include the following sections.

---

## 1. HEADING
A clear title and short description of the architecture.

Example:

```
# HS - Low Power Media Server

A lightweight home server designed for media streaming, backups, and basic self-hosting using low-power hardware.
```

---

## 2. DESCRIPTIVE SHIELDS
Use badges to quickly show important information about the setup.

Examples:

- OS used
- Container system
- Hardware class
- Power consumption
- Difficulty level

Example shields:

```
OS: Ubuntu Server
Runtime: Docker
Hardware: Mini PC / Raspberry Pi
Difficulty: Beginner
Power Usage: Low
```

---

## 3. SERVER / LAB REQUIREMENTS
List the **minimum requirements** needed to run the setup.

Example:
- CPU requirements
- RAM
- Storage
- Network
- Optional hardware

---

## 4. SERVER / LAB SPECIFICATIONS
Provide **recommended specifications** for optimal performance.

Example:
- CPU
- RAM
- Storage layout
- Network configuration
- GPU (if applicable)

---

## 5. ARCHITECTURE
This is the **core section** of the documentation.

Include:

- A visual diagram
- A detailed explanation of the components
- How services interact

For diagrams, use one of the following tools:

- `tldraw`
- `hlbldr`

Explain the architecture clearly, including:

- Service flow
- Network routing
- Storage layers
- Containers or VMs used

---

## 6. HOW TO USE
Explain how to deploy the architecture.

If scripts exist:
- Document what each script does
- Provide usage examples

Example:

```
./install.sh
```

If there are **no scripts**, provide **manual steps using code blocks**.

Example:

```bash
sudo apt update
sudo apt install docker docker-compose
```

> Make sure instructions are **step-by-step and beginner-friendly**.

---

## 7. SOURCES
Provide links to documentation and resources that help users understand the technologies used.

Examples:

- Official documentation
- Guides
- Blog posts
- Research references

---

## 8. MAIN README RELATED INFO
Here, some specific things must be written as:-
```
<!-- HSL_DESCRIPTOR: Short one-line description of this architecture -->
```

The above will enable one to connect with the `github-actions` and auto-sync the changes, and showing the base summary of the directories on the main README.md

---

# Good Contribution Practices

Please try to follow these general principles:

- Write **clear and structured documentation**
- Avoid unnecessary complexity
- Prefer **simple, reproducible setups**
- Include **diagrams whenever possible**
- Comment scripts properly
- Test your architecture before submitting

---

# OPTIONAL (But Recommended)

You may also include:

- `assets/` folder for diagrams and screenshots
- `docker-compose.yml` files
- Example configuration files
- Troubleshooting section
- Performance benchmarks
- Power consumption estimates

---

# FINAL NOTE
The purpose of this project is to make **home servers and home labs accessible to everyone**.

If your contribution helps someone **build, understand, or experiment with self-hosting**, it belongs here.

---

> **HSL** | Created and maintained by **@Th3C0d3Mast3r** and other contributors.