# Architecture

## Overview

The project is designed as a simple and maintainable Linux hardening utility written in Bash.

Instead of trying to implement every available security recommendation, the script focuses on common hardening tasks that are easy to understand, review, and modify.

The project consists of four main components:

* `hardening.sh` – applies security settings.
* `rollback.sh` – restores configuration files from backups.
* `config.conf` – stores user-configurable settings.
* `logs/` and `backups/` – store runtime artifacts.

---

## Workflow

```text
                +----------------+
                |    User Runs   |
                | hardening.sh   |
                +--------+-------+
                         |
                         v
               +------------------+
               | Check Privileges |
               +------------------+
                         |
                         v
               +------------------+
               | Load Configuration |
               +------------------+
                         |
                         v
               +------------------+
               | Create Backups   |
               +------------------+
                         |
                         v
               +------------------+
               | Update Packages  |
               +------------------+
                         |
                         v
               +------------------+
               | Configure UFW    |
               +------------------+
                         |
                         v
               +------------------+
               | Harden SSH       |
               +------------------+
                         |
                         v
               +------------------+
               | Password Policy  |
               +------------------+
                         |
                         v
               +------------------+
               | Auto Updates     |
               +------------------+
                         |
                         v
               +------------------+
               | File Permissions |
               +------------------+
                         |
                         v
               +------------------+
               | Write Log        |
               +------------------+
                         |
                         v
               +------------------+
               | Finish           |
               +------------------+
```

---

## Configuration

The project uses a dedicated configuration file instead of hardcoded values.

All configurable options are stored in:

```text
config.conf
```

This allows changing the script behavior without modifying the source code.

Current configurable options include:

* SSH port
* Password authentication
* UFW enable/disable
* Automatic updates
* Password policy
* Log file location

---

## Backup Strategy

Before modifying any system configuration file, the script creates a backup.

Current backup targets:

* `/etc/ssh/sshd_config`
* `/etc/login.defs`
* `/etc/security/pwquality.conf`

Backup files are stored inside:

```text
backups/
```

The rollback script uses these files to restore the previous configuration.

---

## Logging

All important actions are written to a log file.

Default location:

```text
logs/hardening.log
```

Each log entry contains:

* Timestamp
* Log level
* Message

Example:

```text
[2026-06-28 18:42:01] INFO: Updating package lists.
[2026-06-28 18:42:44] INFO: Configuring UFW.
[2026-06-28 18:43:08] SUCCESS: SSH configuration updated.
```

---

## Error Handling

The project uses several mechanisms to reduce the risk of leaving the system in an inconsistent state.

These include:

* `set -Eeuo pipefail`
* Centralized error handling with `trap`
* Root privilege verification
* SSH configuration validation before restarting the service

If a critical operation fails, the script exits immediately.

---

## Design Goals

This project was designed with the following goals in mind:

* Keep the code readable.
* Avoid unnecessary complexity.
* Separate configuration from source code.
* Create backups before modifying files.
* Produce clear terminal output.
* Keep the project suitable for educational and portfolio purposes.

The project is intentionally lightweight and should be easy to understand for anyone learning Linux administration or Bash scripting.
