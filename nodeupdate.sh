#!/bin/bash
# xray-version-switcher.sh
# فقط برای تعویض نسخه‌ی Xray روی سرورهای MarzNode / V2Ray
# - دانلود و جایگزینی باینری xray
# - بروزرسانی geo* دیتافایل‌ها (اختیاری/بی‌ضرر)
# - ری‌استارت کانتینر marznode اگر پیدا شد
set -euo pipefail

# ===== تنظیمات =====
read -p "Enter XRAY version (e.g. 25.8.3): " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-}
if [[ -z "$XRAY_VERSION" ]]; then
  echo "[-] XRAY_VERSION خالی است."
  exit 1
fi

DATA_DIR="/var/lib/marznode/data"
XRAY_BIN="/var/lib/marznode/xray"
ASSET_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v${XRAY_VERSION}/${ASSET_ZIP}"

TMP_DIR="$(mktemp -d /tmp/xrayupdate.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "[+] Downloading Xray ${XRAY_VERSION} ..."
command -v wget >/dev/null 2>&1 || (apt-get update && apt-get install -y wget)
wget -q -O "${TMP_DIR}/${ASSET_ZIP}" "$XRAY_URL"

echo "[+] Unzipping package ..."
command -v unzip >/dev/null 2>&1 || (apt-get update && apt-get install -y unzip)
unzip -q "${TMP_DIR}/${ASSET_ZIP}" -d "${TMP_DIR}"

# چک وجود باینری
if [[ ! -f "${TMP_DIR}/xray" ]]; then
  echo "[-] فایل باینری xray داخل آرشیو پیدا نشد."
  exit 1
fi

# بکاپ باینری فعلی (اگر وجود دارد)
if [[ -f "$XRAY_BIN" ]]; then
  ts=$(date +%Y%m%d-%H%M%S)
  cp -f "$XRAY_BIN" "${XRAY_BIN}.bak-${ts}"
  echo "[+] Backup created: ${XRAY_BIN}.bak-${ts}"
fi

# اطمینان از وجود مسیر دیتا
mkdir -p "$DATA_DIR"

echo "[+] Installing new xray binary ..."
cp -f "${TMP_DIR}/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

echo "[+] Updating geo files (if present) ..."
for f in geosite.dat geoip.dat; do
  if [[ -f "${TMP_DIR}/${f}" ]]; then
    cp -f "${TMP_DIR}/${f}" "${DATA_DIR}/${f}"
  fi
done

# تلاش برای ری‌استارت کانتینر marznode (اختیاری)
echo "[+] Trying to restart marznode container (if running) ..."
if command -v docker >/dev/null 2>&1; then
  # پیدا کردن یک کانتینر که نامش شامل marznode باشد
  CN=$(docker ps --format '{{.Names}}' | grep -E 'marznode' | head -n 1 || true)
  if [[ -n "${CN:-}" ]]; then
    docker restart "$CN" >/dev/null
    echo "[+] Docker container restarted: $CN"
  else
    # اگر compose در دایرکتوری marznode هست، تلاش برای ری‌استارت سرویس
    if [[ -f "$HOME/marznode/compose.yml" ]]; then
      (cd "$HOME/marznode" && docker compose restart) >/dev/null || true
      echo "[+] docker compose restart attempted in: $HOME/marznode"
    else
      echo "[!] No running marznode container found. Please restart your service manually."
    end
  fi
else
  echo "[!] Docker not found. Just the files were updated; restart your service manually."
fi

echo ""
echo "✅ Xray updated to v${XRAY_VERSION}"
echo "   Binary: $XRAY_BIN"
echo "   Assets: $DATA_DIR/{geosite.dat,geoip.dat}"
