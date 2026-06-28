# Architecture

## Overview

The project is intentionally lightweight and focuses on common Linux hardening tasks that are easy to understand and maintain.

The main script reads configuration values from `config.conf`, creates backups of system configuration files, applies security settings, and writes all actions to a log file.

User
│
│
▼
hardening.sh
│
├── Load configuration
├── Check requirements
├── Create backups
├── Update packages
├── Configure UFW
├── Harden SSH
├── Configure password policy
├── Enable automatic updates
├── Apply file permissions
└── Generate summary


## Configuration

The script does not store hardcoded settings inside the source code.

All user-adjustable values are stored in:

```text
config.conf

This keeps the script simple and makes future changes easier.

#Backups

Before modifying any configuration file, a backup is created inside the backups/ directory.

The rollback script uses these files to restore the previous configuration.

Logging

All important actions are written to:
