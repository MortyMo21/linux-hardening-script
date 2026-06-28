# Linux Hardening Script

A lightweight Bash script for applying basic security hardening on Ubuntu systems.

This project was created as a learning exercise to practice Linux administration, Bash scripting, and basic system hardening techniques. It automates several common security tasks while keeping the implementation simple, readable, and easy to modify.

> **Note**
>
> This script is intended for educational and lab environments. Always review security changes before applying them to production systems.

---

## Features

* System package update
* UFW firewall configuration
* SSH hardening
* Password policy configuration
* Automatic security updates
* Secure permissions for important system files
* Configuration file support
* Backup creation before making changes
* Basic rollback support
* Action logging
* Clear terminal output
* Error handling

---

## Supported System

* Ubuntu 22.04 LTS
* Ubuntu 24.04 LTS

The script should also work on newer Ubuntu releases with little or no modification.

---

## Repository Structure

```
linux-hardening-script/
│
├── README.md
├── LICENSE
├── .gitignore
│
├── hardening.sh
├── rollback.sh
├── config.conf
│
├── backups/
│   └── .gitkeep
│
├── logs/
│   └── .gitkeep
│
├── docs/
│   ├── architecture.md
│   └── rollback.md
│
└── images/
    └── demo.png
```

---

## What the Script Changes

The script performs several common hardening tasks.

### Package Management

* Updates package lists
* Installs available security updates
* Removes unused packages

### Firewall

* Enables UFW
* Denies all incoming connections by default
* Allows outgoing connections
* Allows SSH access

### SSH

* Disables root login
* Limits authentication attempts
* Disables X11 forwarding
* Validates the SSH configuration before restarting the service

### Password Policy

Configures basic password requirements including:

* Minimum password length
* Password expiration
* Warning period before password expiration

### Automatic Updates

Installs and enables unattended security upgrades.

### File Permissions

Applies secure permissions to selected system files such as:

* `/etc/ssh/sshd_config`
* `/etc/passwd`
* `/etc/shadow`

### Logging

Every important action is written to a log file.

Example:

```
[2026-06-28 14:18:33] INFO  Updating package lists
[2026-06-28 14:19:02] INFO  Configuring UFW
[2026-06-28 14:19:15] INFO  Hardening SSH configuration
[2026-06-28 14:19:44] SUCCESS Hardening completed
```

---

## Backups

Before modifying any configuration file, the script creates a backup inside the `backups/` directory.

Example:

```
backups/
├── sshd_config.bak
├── login.defs.bak
└── pwquality.conf.bak
```

These backups can be restored using the rollback script.

---

## Installation

Clone the repository.

```bash
git clone https://github.com/yourusername/linux-hardening-script.git
```

Move into the project directory.

```bash
cd linux-hardening-script
```

Make the scripts executable.

```bash
chmod +x hardening.sh rollback.sh
```

---

## Configuration

The project uses a separate configuration file.

```
config.conf
```

You can adjust settings such as:

* SSH port
* Password policy
* Automatic updates
* Firewall options
* Log file location

No code changes are required for basic customization.

---

## Usage

Run the hardening script as root.

```bash
sudo ./hardening.sh
```

If needed, restore the original configuration.

```bash
sudo ./rollback.sh
```

---

## Example Output

```
=========================================
 Linux Hardening Script
=========================================

[INFO] Loading configuration
[INFO] Updating packages
[INFO] Creating configuration backups
[INFO] Configuring UFW
[INFO] Hardening SSH
[INFO] Configuring password policy
[INFO] Enabling automatic security updates
[INFO] Applying secure file permissions

[SUCCESS] Hardening completed successfully.
```

---

## Rollback

The rollback script restores configuration files that were backed up before hardening.

Current version restores:

* SSH configuration
* Password policy
* Login configuration

The rollback process does not remove installed packages.

---

## Project Goals

This project demonstrates practical knowledge of:

* Linux system administration
* Bash scripting
* Security hardening
* Configuration management
* Logging
* Error handling
* Backup and recovery

The goal is not to replace professional hardening frameworks, but to build a maintainable and readable automation script suitable for learning and portfolio purposes.

---

## Future Improvements

Possible future enhancements include:

* Fail2Ban integration
* Auditd configuration
* Sysctl hardening
* AIDE file integrity monitoring
* CIS Benchmark profile support
* Dry-run mode
* Interactive mode

---

## License

This project is licensed under the MIT License.
