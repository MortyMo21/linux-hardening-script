#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
LOG_FILE="${LOG_DIR}/hardening.log"

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        echo "Error: Please run this script as root."
        exit 1
    fi
}

log() {
    local message="$1"

    printf '[%s] %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" \
        "$message" | tee -a "$LOG_FILE"
}

main() {
    require_root

    mkdir -p "$LOG_DIR"

    log "Linux hardening started."
}

main "$@"
