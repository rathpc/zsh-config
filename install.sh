#!/bin/bash
# install.sh — Install rathpc/zsh-config to your home directory
#
# Usage:
#   ./install.sh                  # Install without 1Password integration
#   ./install.sh --with-1password # Install and include .secrets for 1Password
#
# This script will:
#   - Back up any existing ~/.zsh_config and ~/.zshrc (timestamped)
#   - Copy .zsh_config/ to ~/.zsh_config
#   - Remove the bundled .examples/ directory from the installed copy
#   - Optionally keep .secrets (only with --with-1password)
#   - Append source lines to ~/.zshrc in the correct order (only if missing)

set -euo pipefail

# --- Configuration -----------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/.zsh_config"
ZSH_CONFIG_DEST="${HOME}/.zsh_config"
ZSHRC="${HOME}/.zshrc"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
MARKER="# rathpc/zsh-config"

WITH_1PASSWORD=false

# --- Helpers -----------------------------------------------------------------

log() {
  printf '  %s\n' "$*"
}

info() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf '\n[WARN] %s\n' "$*" >&2
}

err() {
  printf '\n[ERROR] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [--with-1password] [-h|--help]

Options:
  --with-1password   Install the .secrets file for 1Password CLI integration.
                     Without this flag, .secrets is omitted from the install.
  -h, --help         Show this help message and exit.
EOF
}

# --- Parse args --------------------------------------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-1password)
      WITH_1PASSWORD=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      warn "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

# --- Sanity checks -----------------------------------------------------------

if [[ ! -d "${SOURCE_DIR}" ]]; then
  err "Source directory not found: ${SOURCE_DIR}"
fi

info "Installing rathpc/zsh-config"
log "Source:      ${SOURCE_DIR}"
log "Destination: ${ZSH_CONFIG_DEST}"
log "1Password:   ${WITH_1PASSWORD}"

# --- Back up existing config -------------------------------------------------

if [[ -e "${ZSH_CONFIG_DEST}" ]]; then
  BACKUP="${ZSH_CONFIG_DEST}.bak.${TIMESTAMP}"
  info "Backing up existing ~/.zsh_config"
  mv "${ZSH_CONFIG_DEST}" "${BACKUP}"
  log "Saved to: ${BACKUP}"
fi

if [[ -e "${ZSHRC}" ]]; then
  BACKUP_ZSHRC="${ZSHRC}.bak.${TIMESTAMP}"
  info "Backing up existing ~/.zshrc"
  cp "${ZSHRC}" "${BACKUP_ZSHRC}"
  log "Saved to: ${BACKUP_ZSHRC}"
fi

# --- Copy config -------------------------------------------------------------

info "Copying configuration files"
cp -R "${SOURCE_DIR}" "${ZSH_CONFIG_DEST}"
log "Copied ${SOURCE_DIR} -> ${ZSH_CONFIG_DEST}"

# Strip bundled examples — users don't need them at runtime
if [[ -d "${ZSH_CONFIG_DEST}/.examples" ]]; then
  rm -rf "${ZSH_CONFIG_DEST}/.examples"
  log "Removed ${ZSH_CONFIG_DEST}/.examples"
fi

# Strip .secrets and the opload alias unless 1Password integration was requested
if [[ "${WITH_1PASSWORD}" != true ]]; then
  rm -f "${ZSH_CONFIG_DEST}/.secrets"
  log "Removed ${ZSH_CONFIG_DEST}/.secrets (no 1Password integration)"

  ALIASES_FILE="${ZSH_CONFIG_DEST}/.aliases"
  if [[ -f "${ALIASES_FILE}" ]]; then
    grep -v -e '^# opload alias' -e '^alias opload=' "${ALIASES_FILE}" > "${ALIASES_FILE}.tmp"
    mv "${ALIASES_FILE}.tmp" "${ALIASES_FILE}"
    log "Stripped opload alias from .aliases (no 1Password integration)"
  fi
else
  log "Kept ${ZSH_CONFIG_DEST}/.secrets for 1Password integration"
  log "Kept opload alias in .aliases for 1Password integration"
fi

# --- Update .zshrc -----------------------------------------------------------

info "Updating ~/.zshrc"

# Create .zshrc if it doesn't exist
if [[ ! -f "${ZSHRC}" ]]; then
  touch "${ZSHRC}"
  log "Created new ${ZSHRC}"
fi

if grep -q "${MARKER}" "${ZSHRC}"; then
  log "Source block already present in ~/.zshrc — skipping"
else
  log "Appending source block to ~/.zshrc"
  cat >>"${ZSHRC}" <<'EOF'

# rathpc/zsh-config
source ~/.zsh_config/.aliases
source ~/.zsh_config/.exports
source ~/.zsh_config/.tools
source ~/.zsh_config/.paths
EOF
fi

# --- Done --------------------------------------------------------------------

info "Installation complete!"
cat <<EOF

Next steps:
  1. Reload your shell:        source ~/.zshrc
     (or open a new terminal)
  2. Customize your setup:     edit files in ~/.zsh_config/
  3. View documentation:       see ${SCRIPT_DIR}/docs/
EOF

if [[ "${WITH_1PASSWORD}" == true ]]; then
  cat <<EOF
  4. Configure 1Password:      edit ~/.zsh_config/.secrets with your op:// references
  5. Load secrets:             run 'opload' to load secrets into your shell
EOF
fi

printf '\n'
