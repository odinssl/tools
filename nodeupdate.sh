#!/bin/bash
# xray-switch-25.10.15.sh
# Single-command switcher to Xray v25.10.15 for MarzNode/V2Ray stacks.
# It ONLY replaces the xray binary & geo assets, then restarts marznode if found.

set -euo pipefail

# --- Config (change if your paths differ) ---
XRAY_VERSION="25.6.8"
DATA_DIR="/var/lib/marznode/data"
XRAY_BIN="/var/lib/marznode/xray"
ASSET_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/${ASSET_ZIP}"

# --- Helpers ---
log() { echo -e "[xray-switch ${XRAY_VERSION}] $*"; }
need() { command -v "$1" >/dev/null 2>&1 || { log "installing $1 ..."; apt-get update -y && apt-get install -y "$1"; }; }

# --- Preflight ---
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (use: sudo bash)."
  exit 1
fi

TMP_DIR="$(mktemp -d /tmp/xrayupdate.XXXXXX)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# --- Skip if already at target (best-effort) ---
if [[ -x "$XRAY_BIN" ]]; then
  CURR_VER="$("$XRAY_BIN" -version 2>/dev/null | head -n1 | awk '{print $2}' || true)"
  if [[ "$CURR_VER" == "v${XRAY_VERSION}" ]]; then
    log "already at v${XRAY_VERSION}; nothing to do."
    exit 0
  fi
fi

# --- Download & unpack ---
need wget
need unzip
log "downloading: $XRAY_URL"
wget -q -O "${TMP_DIR}/${ASSET_ZIP}" "$XRAY_URL"

log "unpacking..."
unzip -q "${TMP_DIR}/${ASSET_ZIP}" -d "${TMP_DIR}"

if [[ ! -f "${TMP_DIR}/xray" ]]; then
  echo "xray binary not found in archive."; exit 1
fi

# --- Backup & install ---
mkdir -p "$DATA_DIR"
if [[ -f "$XRAY_BIN" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  cp -f "$XRAY_BIN" "${XRAY_BIN}.bak-${ts}"
  log "backup: ${XRAY_BIN}.bak-${ts}"
fi

log "installing binary -> $XRAY_BIN"
cp -f "${TMP_DIR}/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

log "updating geo assets (if present)"
for f in geosite.dat geoip.dat; do
  [[ -f "${TMP_DIR}/${f}" ]] && cp -f "${TMP_DIR}/${f}" "${DATA_DIR}/${f}"
done

# --- Restart marznode if running ---
log "restarting marznode container (if running)"
if command -v docker >/dev/null 2>&1; then
  CN="$(docker ps --format '{{.Names}}' | grep -E 'marznode' | head -n 1 || true)"
  if [[ -n "${CN:-}" ]]; then
    docker restart "$CN" >/dev/null && log "docker container restarted: $CN"
  elif [[ -f "$HOME/marznode/compose.yml" ]]; then
    (cd "$HOME/marznode" && docker compose restart) >/dev/null || true
    log "docker compose restart attempted in: $HOME/marznode"
  else
    log "no running marznode container found; restart manually if needed."
  fi
else
  log "docker not found; files updated only."
fi

# --- Report ---
NEW_VER="$("$XRAY_BIN" -version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")"
echo
echo "✅ Xray switched to ${NEW_VER}"
echo "   Binary: $XRAY_BIN"
echo "   Assets: $DATA_DIR/{geosite.dat,geoip.dat}"
