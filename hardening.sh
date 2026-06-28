#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

readonly CONFIG_FILE="${SCRIPT_DIR}/config.conf"
readonly BACKUP_DIR="${SCRIPT_DIR}/backups"
readonly LOG_DIR="${SCRIPT_DIR}/logs"

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
    echo "        Linux Hardening Script"
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

    error "Script failed on line ${BASH_LINENO[0]}."

    exit "$exit_code"
}

trap error_handler ERR

require_root() {
    if [[ $EUID -ne 0 ]]; then
        die "This script must be run as root."
    fi
}

load_config() {

    [[ -f "$CONFIG_FILE" ]] || die "Configuration file not found."

    # shellcheck source=/dev/null
    source "$CONFIG_FILE"

    LOG_FILE="${SCRIPT_DIR}/${LOG_FILE}"

    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"

    touch "$LOG_FILE"
}

backup_file() {

    local file=$1

    [[ -f "$file" ]] || return
    
    local backup="${BACKUP_DIR}/$(basename "$file").bak"
    
    if [[ ! -f "$backup" ]]; then
        cp -p "$file" "$backup"

        info "Backup created: $(basename "$backup")"
    fi

}

replace_or_append() {

    local file=$1
    local key=$2
    local value=$3

    if grep -Eq "^[#[:space:]]*${key}" "$file"; then

        sed -Ei \
            "s|^[#[:space:]]*${key}.*|${key} ${value}|" \
            "$file"

    else

        echo "${key} ${value}" >> "$file"

    fi

}

replace_equal_value() {

    local file=$1
    local key=$2
    local value=$3

    if grep -Eq "^${key}" "$file"; then

        sed -Ei \
            "s|^${key}.*|${key} = ${value}|" \
            "$file"

    else

        echo "${key} = ${value}" >> "$file"

    fi

}

create_backups() {

    info "Creating configuration backups..."

    backup_file "$SSH_CONFIG"
    backup_file "$LOGIN_DEFS"
    backup_file "$PWQUALITY_CONF"

    success "Backups created."

}

update_system() {

    info "Updating package lists..."

    apt-get update -y

    info "Upgrading installed packages..."

    DEBIAN_FRONTEND=noninteractive \
        apt-get upgrade -y

    info "Removing unused packages..."

    apt-get autoremove -y

    success "System packages updated."

}

install_dependencies() {

    info "Checking required packages..."

    local packages=(
        ufw
        unattended-upgrades
        libpam-pwquality
    )

    local missing=()

    for package in "${packages[@]}"; do
        if ! dpkg -s "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if ((${#missing[@]})); then

        info "Installing missing packages..."

        apt-get install -y "${missing[@]}"

    else

        info "All required packages are already installed."

    fi

}

configure_ufw() {

    if [[ "${ENABLE_UFW}" != "yes" ]]; then
        warning "UFW configuration skipped."
        return
    fi

    info "Configuring UFW..."


    ufw default deny incoming
    ufw default allow outgoing

    ufw status | grep -q "${SSH_PORT}/tcp" || ufw allow "${SSH_PORT}/tcp"

    ufw --force enable

    success "UFW configured."

}

configure_ssh() {

    info "Applying SSH hardening..."

    backup_file "$SSH_CONFIG"

    replace_or_append \
        "$SSH_CONFIG" \
        "Port" \
        "$SSH_PORT"

    replace_or_append \
        "$SSH_CONFIG" \
        "PermitRootLogin" \
        "no"

    replace_or_append \
        "$SSH_CONFIG" \
        "PasswordAuthentication" \
        "$ALLOW_PASSWORD_AUTH"

    replace_or_append \
        "$SSH_CONFIG" \
        "PermitEmptyPasswords" \
        "no"

    replace_or_append \
        "$SSH_CONFIG" \
        "PubkeyAuthentication" \
        "yes"

    replace_or_append \
        "$SSH_CONFIG" \
        "MaxAuthTries" \
        "3"

    replace_or_append \
        "$SSH_CONFIG" \
        "LoginGraceTime" \
        "30"

    replace_or_append \
        "$SSH_CONFIG" \
        "X11Forwarding" \
        "no"

    replace_or_append \
        "$SSH_CONFIG" \
        "ClientAliveInterval" \
        "300"

    replace_or_append \
        "$SSH_CONFIG" \
        "ClientAliveCountMax" \
        "2"

    replace_or_append \
        "$SSH_CONFIG" \
        "UseDNS" \
        "no"
        
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

show_firewall_status() {

    info "Firewall status"

    ufw status verbose

}

show_ssh_status() {

    info "SSH service status"

    systemctl --no-pager --full status ssh \
        | head -n 12

}

configure_password_policy() {

    info "Configuring password policy..."

    backup_file "$LOGIN_DEFS"
    backup_file "$PWQUALITY_CONF"

    replace_or_append \
        "$LOGIN_DEFS" \
        "PASS_MAX_DAYS" \
        "$PASSWORD_MAX_DAYS"

    replace_or_append \
        "$LOGIN_DEFS" \
        "PASS_MIN_DAYS" \
        "$PASSWORD_MIN_DAYS"

    replace_or_append \
        "$LOGIN_DEFS" \
        "PASS_WARN_AGE" \
        "$PASSWORD_WARN_DAYS"

    replace_equal_value \
        "$PWQUALITY_CONF" \
        "minlen" \
        "$PASSWORD_MIN_LENGTH"

    replace_equal_value \
        "$PWQUALITY_CONF" \
        "dcredit" \
        "-1"

    replace_equal_value \
        "$PWQUALITY_CONF" \
        "ucredit" \
        "-1"

    replace_equal_value \
        "$PWQUALITY_CONF" \
        "lcredit" \
        "-1"

    replace_equal_value \
        "$PWQUALITY_CONF" \
        "ocredit" \
        "-1"

    success "Password policy configured."

}

configure_auto_updates() {

    if [[ "$ENABLE_AUTO_UPDATES" != "yes" ]]; then
        warning "Automatic updates are disabled in the configuration."
        return
    fi

    info "Configuring unattended upgrades..."

    cat >/etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

    systemctl enable unattended-upgrades >/dev/null 2>&1 || true
    systemctl restart unattended-upgrades >/dev/null 2>&1 || true

    success "Automatic security updates enabled."

}

secure_file_permissions() {

    info "Checking important file permissions..."

    if [[ -f "$SSH_CONFIG" ]]; then
        chmod 600 "$SSH_CONFIG"
    fi

    if [[ -f "$LOGIN_DEFS" ]]; then
        chmod 644 "$LOGIN_DEFS"
    fi

    if [[ -f "$PWQUALITY_CONF" ]]; then
        chmod 644 "$PWQUALITY_CONF"
    fi

    success "File permissions updated."

}

system_summary() {

    echo
    echo "========== Summary =========="
    echo

    echo "Firewall"

    ufw status verbose

    echo

    echo "SSH"

    grep -E "^[# ]*(Port|PermitRootLogin|PasswordAuthentication)" "$SSH_CONFIG" \
        "$SSH_CONFIG"

    echo

    echo "Automatic Updates"

    if [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]]; then
        cat /etc/apt/apt.conf.d/20auto-upgrades
    fi

    echo

}

check_requirements() {

    local commands=(
        apt-get
        systemctl
        ufw
        grep
        sed
        cp
    )

    info "Checking system requirements..."

    for cmd in "${commands[@]}"; do
        command -v "$cmd" >/dev/null 2>&1 \
            || die "Required command not found: $cmd"
    done

    if ! dpkg -s openssh-server >/dev/null 2>&1; then
        info "Installing OpenSSH Server..."
        apt-get install -y openssh-server
    fi
    
    success "All required commands are available."

}

main() {

    print_banner

    require_root

    load_config

    info "Starting Linux hardening..."

    check_requirements

    create_backups

    update_system

    install_dependencies

    configure_ufw

    configure_ssh

    configure_password_policy

    configure_auto_updates

    secure_file_permissions

    system_summary

    echo

    success "Linux hardening completed."

    echo "Configuration file:"
    echo "  $CONFIG_FILE"
    
    echo

    echo "Log file:"
    echo "  $LOG_FILE"

    echo

    echo "Backups:"
    echo "  $BACKUP_DIR"

    echo

}

main "$@"
