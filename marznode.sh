#!/bin/bash
set -e

# === USER INPUT ===
read -p "📦 Enter service port (default: 59100): " SERVICE_PORT
read -p "🌀 Enter desired Xray version (default: 25.3.6): " XRAY_VERSION

SERVICE_PORT=${SERVICE_PORT:-59100}
XRAY_VERSION=${XRAY_VERSION:-25.3.6}
XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/$XRAY_ZIP"

DATA_DIR="/var/lib/marznode/data"
XRAY_BIN="/var/lib/marznode/xray"
COMPOSE_FILE="$HOME/marznode/compose.yml"

# === FIX DNS BEFORE WARP ===
echo "🔧 Setting resolv.conf with Cloudflare DNS..."
rm -rf /etc/resolv.conf
echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf
chattr +i /etc/resolv.conf

# === INSTALL DOCKER ===
echo "🚀 Installing Docker..."
curl -fsSL https://get.docker.com | sh

# === CREATE DIRECTORIES ===
mkdir -p /var/lib/marznode/certs
mkdir -p "$DATA_DIR"

# === GET CERTIFICATES ===
echo "🔐 Paste client.pem"
${EDITOR:-nano} /var/lib/marznode/client.pem

echo "📄 Paste fullchain.pem"
${EDITOR:-nano} /var/lib/marznode/certs/fullchain.pem

echo "🔑 Paste key.pem"
${EDITOR:-nano} /var/lib/marznode/certs/key.pem

# === DOWNLOAD XRAY CONFIG ===
curl -L https://github.com/marzneshin/marznode/raw/master/xray_config.json -o /var/lib/marznode/xray_config.json

# === CLONE MARZNODE ===
cd ~
git clone https://github.com/marzneshin/marznode || true
cd marznode

# === INJECT ENVIRONMENT VARIABLES ===
sed -i "/^\s*environment:/a \ \ \ \ \ \ SERVICE_PORT: \"$SERVICE_PORT\"\n\ \ \ \ \ \ INSECURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE_INTERVAL: \"5\"" ./compose.yml

# === ADD COMMAND TO ENFORCE NEW XRAY PATH ===
if ! grep -q 'command:' "$COMPOSE_FILE"; then
  echo "🔧 Adding command override to compose.yml"
  awk '
  /image:/ {
    print;
    print "    command: [\"/var/lib/marznode/xray\", \"-c\", \"/var/lib/marznode/xray_config.json\"]";
    next
  }
  { print }
  ' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"
fi

# === INSTALL wgcf + wireguard IF NEEDED ===
cd ~
wget -O wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.27/wgcf_2.2.27_linux_amd64
chmod +x wgcf && mv wgcf /usr/bin/wgcf

if ! command -v wg-quick >/dev/null; then
  echo "🧩 Installing WireGuard tools..."
  apt update && apt install -y wireguard wireguard-tools
fi

# === CONFIGURE WARP ===
wgcf register || true
wgcf generate
sed -i '/MTU = 1280/a Table = off' wgcf-profile.conf
mkdir -p /etc/wireguard
cp wgcf-profile.conf /etc/wireguard/warp.conf

echo "⚙️ Starting wg-quick@warp..."
if systemctl start wg-quick@warp 2>/dev/null; then
  echo "✅ Warp started."
else
  echo "❌ Failed to start wg-quick@warp."
  read -p "❓ Continue anyway? [y/N]: " choice
  case "$choice" in
    y|Y ) echo "🔁 Continuing...";;
    * ) echo "🛑 Aborting."; exit 1;;
  esac
fi

systemctl enable wg-quick@warp 2>/dev/null || true

# === DOWNLOAD & INSTALL XRAY ===
echo "⬇️ Downloading Xray $XRAY_VERSION..."
cd "$DATA_DIR"
apt install -y unzip
wget -q "$XRAY_URL"
unzip -o "$XRAY_ZIP"
rm -f "$XRAY_ZIP"
cp "$DATA_DIR/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

# === RESTART MARZNODE ===
cd ~/marznode
docker compose down
docker compose up -d

# === FINAL OUTPUT ===
echo
echo "🎉 Setup completed successfully!"
echo "---------------------------------------------"
echo "🔐 Xray x25519 key pair:"
docker exec marznode-marznode-1 /var/lib/marznode/xray x25519 || echo "⚠️ x25519 command failed"

echo
echo "🔑 Random hex (openssl rand -hex 8):"
openssl rand -hex 8 || echo "⚠️ openssl not found"

echo
echo "📦 SERVICE_PORT: $SERVICE_PORT"
echo "🌀 XRAY_VERSION: $XRAY_VERSION"

echo "---------------------------------------------"
