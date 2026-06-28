#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly CONFIG_FILE="${SCRIPT_DIR}/config.conf"
readonly BACKUP_DIR="${SCRIPT_DIR}/backups"

LOG_FILE=""

SSH_CONFIG="/etc/ssh/sshd_config"
LOGIN_DEFS="/etc/login.defs"
PWQUALITY_CONF="/etc/security/pwquality.conf"

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

print_banner() {

    command -v clear >/dev/null && clear

    echo "========================================="
    echo "         Rollback Configuration"
    echo "========================================="
    echo

}

info() {

    echo -e "${BLUE}[INFO]${RESET} $1"
    echo "[$(date '+%F %T')] INFO: $1" >> "$LOG_FILE"

}

success() {

    echo -e "${GREEN}[OK]${RESET} $1"
    echo "[$(date '+%F %T')] SUCCESS: $1" >> "$LOG_FILE"

}

warning() {

    echo -e "${YELLOW}[WARNING]${RESET} $1"
    echo "[$(date '+%F %T')] WARNING: $1" >> "$LOG_FILE"

}

error() {

    echo -e "${RED}[ERROR]${RESET} $1"
    echo "[$(date '+%F %T')] ERROR: $1" >> "$LOG_FILE"

}

die() {

    error "$1"
    exit 1

}

error_handler() {

    local exit_code=$?

    error "Rollback failed on line ${BASH_LINENO[0]}."

    exit "$exit_code"

}

trap error_handler ERR

require_root() {

    [[ $EUID -eq 0 ]] || die "This script must be run as root."

}

load_config() {

    [[ -f "$CONFIG_FILE" ]] || die "Configuration file not found."

    # shellcheck source=/dev/null
    source "$CONFIG_FILE"

    LOG_FILE="${SCRIPT_DIR}/${LOG_FILE}"

    mkdir -p "$(dirname "$LOG_FILE")"

    touch "$LOG_FILE"

}

restore_file() {

    local backup_file="$1"
    local destination="$2"

    if [[ ! -f "$backup_file" ]]; then
        warning "Backup not found: $(basename "$backup_file")"
        return
    fi
    
    if cp -p "$backup_file" "$destination"; then
        success "Restored $(basename "$destination")"
    else
        die "Failed to restore $(basename "$destination")"
    fi

}

restart_ssh() {

    info "Validating SSH configuration..."
    
    if command -v sshd >/dev/null 2>&1; then
    
        if sshd -t; then
    
            systemctl restart ssh
    
            success "SSH configuration updated."
    
        else
    
            die "SSH configuration validation failed."
    
        fi
    
    else
    
        die "Unable to locate sshd binary."
    
    fi

}

main() {

    print_banner

    require_root

    load_config

    info "Starting rollback..."

    restore_file \
        "${BACKUP_DIR}/sshd_config.bak" \
        "$SSH_CONFIG"

    restore_file \
        "${BACKUP_DIR}/login.defs.bak" \
        "$LOGIN_DEFS"

    restore_file \
        "${BACKUP_DIR}/pwquality.conf.bak" \
        "$PWQUALITY_CONF"

    if [[ -f "${BACKUP_DIR}/sshd_config.bak" ]]; then
        restart_ssh
    fi

    echo

    success "Rollback completed."

    echo
    echo "Backup directory:"
    echo "  $BACKUP_DIR"
    echo


    echo "Log file:"
    echo "  $LOG_FILE"

    echo

}

main "$@"
