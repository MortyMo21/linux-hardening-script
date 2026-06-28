# Rollback

## Overview

The project includes a rollback script that restores configuration files modified by the hardening process.

The rollback feature is intentionally simple and focuses on restoring backed-up configuration files instead of reverting every system change.

---

## Purpose

The rollback script allows you to quickly restore the original configuration if you are not satisfied with the applied hardening settings or if you need to return the system to its previous state.

---

## Restored Files

Currently the rollback process restores the following files:

- `/etc/ssh/sshd_config`
- `/etc/login.defs`
- `/etc/security/pwquality.conf`

The script restores only files that have an available backup.

---

## Backup Location

All backups are stored inside the project directory.

```text
backups/
```

Each file is copied before any modifications are made by `hardening.sh`.

---

## Usage

Run the rollback script with root privileges.

```bash
sudo ./rollback.sh
```

---

## Rollback Process

The rollback script performs the following steps:

1. Checks for root privileges.
2. Loads the project configuration.
3. Restores available backup files.
4. Validates the SSH configuration.
5. Restarts the SSH service if validation succeeds.
6. Writes actions to the log file.

---

## Logging

Rollback events are written to the same log file used by the hardening script.

Default location:

```text
logs/hardening.log
```

Example:

```text
[2026-06-28 19:11:04] INFO: Starting rollback.
[2026-06-28 19:11:05] SUCCESS: Restored sshd_config.
[2026-06-28 19:11:06] SUCCESS: SSH service restarted.
[2026-06-28 19:11:06] SUCCESS: Rollback completed.
```

---

## Limitations

The rollback script restores configuration files only.

It does not:

- remove installed packages
- disable UFW
- revert package updates
- uninstall unattended-upgrades
- restore previous package versions

These actions should be performed manually if required.

---

## Notes

Always verify that backup files exist before running the rollback script.

If a backup file is missing, the corresponding configuration file cannot be restored.
