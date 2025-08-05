#!/bin/bash
set -e

# --- USER INPUTS ---
read -p "📦 Enter service port (default: 59100): " SERVICE_PORT
read -p "🌀 Enter desired Xray version (default: 25.3.6): " XRAY_VERSION

SERVICE_PORT=${SERVICE_PORT:-59100}
XRAY_VERSION=${XRAY_VERSION:-25.3.6}

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

# --- INSTALL WGCF & WARP CONFIG ---
cd ~
wget -O wgcf https://github.com/ViRb3/wgcf/releases/download/v2.2.27/wgcf_2.2.27_linux_amd64
chmod +x wgcf && sudo mv wgcf /usr/bin/wgcf
wgcf register || true
wgcf generate
sed -i '/MTU = 1280/a Table = off' wgcf-profile.conf
sudo mkdir -p /etc/wireguard
sudo cp wgcf-profile.conf /etc/wireguard/warp.conf
sudo systemctl start wg-quick@warp
sudo systemctl enable wg-quick@warp

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

# --- RESTART XRAY + DOCKER DNS ---
echo '{"dns": ["1.1.1.1", "1.0.0.1"]}' | sudo tee /etc/docker/daemon.json
sudo systemctl restart docker
docker restart marznode-marznode-1
rm -rf /etc/resolv.conf && echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf
chattr +i /etc/resolv.conf

# --- INSTALL NETWORK OPTIMIZER (BBR) ---
sudo apt-get -o Acquire::ForceIPv4=true update
sudo apt-get -o Acquire::ForceIPv4=true install -y sudo curl jq
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/develfishere/Linux_NetworkOptimizer/main/bbr.sh)

echo "✅ Setup completed successfully!"
