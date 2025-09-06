#!/bin/bash
# xray-switch-25.6.8.sh
# Switch Xray to v25.6.8 for stacks using "marznodeodin" paths/container names.
# - Replaces binary and geo assets
# - Restarts docker container if found
set -euo pipefail

# --- Config (all paths adapted to marznodeodin) ---
XRAY_VERSION="25.6.8"
BASE_DIR="/var/lib/marznodeodin"
DATA_DIR="${BASE_DIR}/data"
XRAY_BIN="${BASE_DIR}/xray"
ASSET_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/${ASSET_ZIP}"

# docker compose project dir (if you used compose)
COMPOSE_DIR="${HOME}/marznodeodin"   # changed from ~/marznode to ~/marznodeodin
COMPOSE_FILE="${COMPOSE_DIR}/compose.yml"

log() { echo -e "[xray-switch ${XRAY_VERSION}] $*"; }
need() { command -v "$1" >/dev/null 2>&1 || { log "installing $1 ..."; apt-get update -y && apt-get install -y "$1"; }; }

# Root check
if [[ $EUID -ne 0 ]]; then
  echo "Please run as root (use: sudo bash)."
  exit 1
fi

TMP_DIR="$(mktemp -d /tmp/xrayupdate.XXXXXX)"
cleanup(){ rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Already at target?
if [[ -x "$XRAY_BIN" ]]; then
  CURR_VER="$("$XRAY_BIN" -version 2>/dev/null | head -n1 | awk '{print $2}' || true)"
  if [[ "$CURR_VER" == "v${XRAY_VERSION}" ]]; then
    log "already at v${XRAY_VERSION}; nothing to do."
    exit 0
  fi
fi

# Download & unpack
need wget
need unzip
log "downloading: $XRAY_URL"
wget -q -O "${TMP_DIR}/${ASSET_ZIP}" "$XRAY_URL"

log "unpacking..."
unzip -q "${TMP_DIR}/${ASSET_ZIP}" -d "${TMP_DIR}"

[[ -f "${TMP_DIR}/xray" ]] || { echo "xray binary not found in archive."; exit 1; }

# Install
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

# Restart docker container
log "restarting docker container (if running)"
if command -v docker >/dev/null 2>&1; then
  # Prefer exact marznodeodin; fallback to anything containing marznode
  CN="$(docker ps --format '{{.Names}}' | grep -E '^marznodeodin' | head -n1 || true)"
  if [[ -z "${CN}" ]]; then
    CN="$(docker ps --format '{{.Names}}' | grep -E 'marznode' | head -n1 || true)"
  fi

  if [[ -n "${CN:-}" ]]; then
    docker restart "$CN" >/dev/null && log "docker container restarted: $CN"
  elif [[ -f "$COMPOSE_FILE" ]]; then
    (cd "$COMPOSE_DIR" && docker compose restart) >/dev/null || true
    log "docker compose restart attempted in: $COMPOSE_DIR"
  else
    log "no running container or compose file found; restart your service manually if needed."
  fi
else
  log "docker not found; files updated only."
fi

NEW_VER="$("$XRAY_BIN" -version 2>/dev/null | head -n1 | awk '{print $2}' || echo "unknown")"
echo
echo "✅ Xray switched to ${NEW_VER}"
echo "   Binary: $XRAY_BIN"
echo "   Assets: $DATA_DIR/{geosite.dat,geoip.dat}"
