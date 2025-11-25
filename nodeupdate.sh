#!/bin/bash
# xray-safe-update.sh
# Safely updates Xray to v25.10.15 by stopping the service first.

set -euo pipefail

# --- Config ---
XRAY_VERSION="25.10.15"
DATA_DIR="/var/lib/marznode/data"
XRAY_BIN="/var/lib/marznode/xray"
ASSET_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/${ASSET_ZIP}"

# --- Helpers ---
log() { echo -e "\033[1;32m[xray-updater]\033[0m $*"; }
err() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }
need() { command -v "$1" >/dev/null 2>&1 || { log "installing $1 ..."; apt-get update -y && apt-get install -y "$1"; }; }

# --- Preflight ---
if [[ $EUID -ne 0 ]]; then
  err "Please run as root."
  exit 1
fi

TMP_DIR="$(mktemp -d /tmp/xrayupdate.XXXXXX)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- 1. Download & Unpack ---
need wget
need unzip

log "Downloading Xray v${XRAY_VERSION}..."
if ! wget -q -O "${TMP_DIR}/${ASSET_ZIP}" "$XRAY_URL"; then
  err "Download failed! Check your internet connection."
  exit 1
fi

log "Unpacking..."
unzip -q "${TMP_DIR}/${ASSET_ZIP}" -d "${TMP_DIR}"

if [[ ! -f "${TMP_DIR}/xray" ]]; then
  err "Extracted archive does not contain 'xray' binary."
  exit 1
fi

# --- 2. Stop Service (Crucial Step) ---
CONTAINER_NAME=""
if command -v docker >/dev/null 2>&1; then
  CONTAINER_NAME="$(docker ps -a --format '{{.Names}}' | grep -E 'marznode' | head -n 1 || true)"
  if [[ -n "$CONTAINER_NAME" ]]; then
    log "Stopping container: $CONTAINER_NAME to release file locks..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  fi
fi

# --- 3. Backup & Install ---
mkdir -p "$DATA_DIR"

# Backup
if [[ -f "$XRAY_BIN" ]]; then
  cp -f "$XRAY_BIN" "${XRAY_BIN}.bak"
fi

log "Installing new binary..."
cp -f "${TMP_DIR}/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

# Fix ownership (Ensure root owns it so Docker mapping works)
chown root:root "$XRAY_BIN"

log "Updating assets..."
for f in geosite.dat geoip.dat; do
  [[ -f "${TMP_DIR}/${f}" ]] && cp -f "${TMP_DIR}/${f}" "${DATA_DIR}/${f}"
done

# --- 4. Verification (Test before Start) ---
log "Verifying binary integrity..."
if ! "$XRAY_BIN" -version >/dev/null 2>&1; then
  err "The new binary is corrupted or not executable!"
  log "Restoring backup..."
  [[ -f "${XRAY_BIN}.bak" ]] && mv "${XRAY_BIN}.bak" "$XRAY_BIN" && chmod +x "$XRAY_BIN"
  
  # Try to start anyway with old bin
  [[ -n "$CONTAINER_NAME" ]] && docker start "$CONTAINER_NAME"
  exit 1
fi

# --- 5. Restart Service ---
if [[ -n "$CONTAINER_NAME" ]]; then
  log "Starting container: $CONTAINER_NAME..."
  docker start "$CONTAINER_NAME" >/dev/null
  log "Done! Container restarted."
elif [[ -f "$HOME/marznode/compose.yml" ]]; then
  log "Starting via docker compose..."
  (cd "$HOME/marznode" && docker compose up -d --force-recreate)
else
  log "Warning: Could not find running container to restart. Please restart Marznode manually."
fi

# --- Report ---
NEW_VER="$("$XRAY_BIN" -version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")"
echo
echo "✅ Update Successful: ${NEW_VER}"
