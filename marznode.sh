#!/bin/bash
set -e

# --- USER INPUT ---
read -p "📦 Enter service port (default: 59100): " SERVICE_PORT
read -p "🌀 Enter desired Xray version (default: 25.3.6): " XRAY_VERSION

SERVICE_PORT=${SERVICE_PORT:-59100}
XRAY_VERSION=${XRAY_VERSION:-25.3.6}

# --- FIX DNS BEFORE WARP ---
echo "🔧 Setting custom resolv.conf with Cloudflare DNS..."
rm -rf /etc/resolv.conf
echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf
chattr +i /etc/resolv.conf

# --- INSTALL DOCKER ---
echo "🚀 Installing Docker..."
curl -fsSL https://get.docker.com | sh

# --- CREATE DIRECTORIES ---
mkdir -p /var/lib/marznode/certs
mkdir -p /var/lib/marznode/data

# --- GET CERTIFICATES ---
echo "🔐 Paste your client certificate (client.pem). The editor will open. Save and exit when done."
${EDITOR:-nano} /var/lib/marznode/client.pem

echo "📄 Paste your fullchain.pem (TLS certificate). The editor will open. Save and exit when done."
${EDITOR:-nano} /var/lib/marznode/certs/fullchain.pem

echo "🔑 Paste your key.pem (TLS private key). The editor will open. Save and exit when done."
${EDITOR:-nano} /var/lib/marznode/certs/key.pem

# --- DOWNLOAD XRAY CONFIG ---
curl -L https://github.com/marzneshin/marznode/raw/master/xray_config.json -o /var/lib/marznode/xray_config.json

# --- CLONE MARZNODE REPO ---
cd ~
git clone https://github.com/marzneshin/marznode || true
cd marznode

# --- UPDATE COMPOSE.YML ---
sed -i "/^\s*environment:/a \ \ \ \ \ \ SERVICE_PORT: \"$SERVICE_PORT\"\n\ \ \ \ \ \ INSECURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE_INTERVAL: \"5\"" ./compose.yml

# --- START MARZNODE ---
docker compose -f ./compose.yml up -d

# --- INSTALL wgcf + wireguard IF NEEDED ---
cd ~
wget -O wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.27/wgcf_2.2.27_linux_amd64
chmod +x wgcf && sudo mv wgcf /usr/bin/wgcf

if ! command -v wg-quick >/dev/null; then
  echo "🧩 Installing missing WireGuard tools (wg, wg-quick)..."
  sudo apt update && sudo apt install -y wireguard wireguard-tools
fi

# --- CONFIGURE WARP ---
wgcf register || true
wgcf generate
sed -i '/MTU = 1280/a Table = off' wgcf-profile.conf
sudo mkdir -p /etc/wireguard
sudo cp wgcf-profile.conf /etc/wireguard/warp.conf

echo "⚙️ Attempting to start WireGuard warp interface..."
if systemctl start wg-quick@warp 2>/dev/null; then
  echo "✅ Warp interface started successfully."
else
  echo "❌ Failed to start wg-quick@warp."

  read -p "❓ Do you want to continue anyway? [y/N]: " choice
  case "$choice" in
    y|Y ) echo "🔁 Continuing setup...";;
    * ) echo "🛑 Aborted due to Warp failure."; exit 1;;
  esac
fi

if systemctl enable wg-quick@warp 2>/dev/null; then
  echo "✅ Warp interface enabled at boot."
else
  echo "⚠️ Could not enable wg-quick@warp. Skipped."
fi

# --- UPGRADE XRAY CORE ---
echo "⬇️ Downloading Xray version $XRAY_VERSION..."
apt update && apt install -y unzip
cd /var/lib/marznode/data
XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/$XRAY_ZIP"
wget "$XRAY_URL"
unzip "$XRAY_ZIP"
rm "$XRAY_ZIP"
cp /var/lib/marznode/data/xray /var/lib/marznode/xray
chmod +x /var/lib/marznode/xray

# --- SET XRAY PATHS IN COMPOSE ---
COMPOSE_FILE=~/marznode/compose.yml
sed -i '/XRAY_EXECUTABLE_PATH:/d' "$COMPOSE_FILE"
sed -i '/XRAY_ASSETS_PATH:/d' "$COMPOSE_FILE"
awk '
/environment:/ {
  print;
  print "      XRAY_EXECUTABLE_PATH: \"/var/lib/marznode/xray\"";
  print "      XRAY_ASSETS_PATH: \"/var/lib/marznode/data\"";
  next
}
{ print }
' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"

# --- RESTART MARZNODE WITH NEW CORE ---
docker compose -f "$COMPOSE_FILE" down
docker compose -f "$COMPOSE_FILE" up -d

# --- INSTALL NETWORK OPTIMIZER (BBR) ---
sudo apt-get -o Acquire::ForceIPv4=true update
sudo apt-get -o Acquire::ForceIPv4=true install -y sudo curl jq
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/develfishere/Linux_NetworkOptimizer/main/bbr.sh)

# --- FINAL OUTPUT ---
echo
echo "🎉 All done! Here are some important outputs:"
echo "---------------------------------------------"
echo "🔐 Xray x25519 key pair:"
docker exec marznode-marznode-1 xray x25519 || echo "⚠️ Could not generate x25519 inside container."

echo
echo "🔑 Random hex (openssl rand -hex 8):"
openssl rand -hex 8 || echo "⚠️ openssl not found."

echo
echo "📦 Selected SERVICE_PORT: $SERVICE_PORT"
echo "🌀 Selected XRAY_VERSION: $XRAY_VERSION"
echo "---------------------------------------------"
