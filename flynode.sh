#!/bin/bash
# MarzNode Xray Installation Script (Cleaned & Hardened for GitHub)
# Author: Gemini (AI)
#
# Usage: bash <(curl -fsSL YOUR_GIST_OR_RAW_LINK)

# --- GLOBAL SETTINGS & ERROR HANDLING ---
# Exit immediately if a command exits with a non-zero status.
# Treat unset variables as an error.
# The return code of a pipeline is the return code of the last command to exit with a non-zero status.
set -euo pipefail

# --- DEFAULTS ---
SERVICE_PORT_DEFAULT="59101"
XRAY_VERSION_DEFAULT="1.8.10" # نسخه پایدار و رایج
PROJECT_NAME_DEFAULT="marznode"
DEFAULT_XRAY_CONFIG_URL="https://raw.githubusercontent.com/marzneshin/marznode/master/xray_config.json"

# --- USER INPUTS ---
read -r -p "Enter service port [default: $SERVICE_PORT_DEFAULT]: " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-$SERVICE_PORT_DEFAULT}

read -r -p "Enter XRAY version [default: $XRAY_VERSION_DEFAULT]: " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-$XRAY_VERSION_DEFAULT}

read -r -p "Enter MarzNode project name [default: $PROJECT_NAME_DEFAULT]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-$PROJECT_NAME_DEFAULT}

# --- CRITICAL PATHS ---
BASE_DIR="/var/lib/$PROJECT_NAME"
CERTS_DIR="$BASE_DIR/certs"
DATA_DIR="$BASE_DIR/data"
XRAY_BIN="$BASE_DIR/xray"
CONFIG_FILE="$BASE_DIR/xray_config.json"
INSTALL_DIR="$HOME/$PROJECT_NAME"
COMPOSE_FILE="$INSTALL_DIR/compose.yml"
CONTAINER_NAME="${PROJECT_NAME}-marznode-1"

echo "===================================================="
echo "   MARZNODE INSTALLATION STARTED 🚀"
echo "   Project: $PROJECT_NAME"
echo "   Service Port: $SERVICE_PORT"
echo "   Xray Version: $XRAY_VERSION"
echo "===================================================="

# --- 1. INSTALL DOCKER ---
echo "[+] Installing Docker..."
if ! command -v docker &> /dev/null; then
    if ! curl -fsSL https://get.docker.com | sh; then
        echo "❌ Error: Failed to install Docker. Exiting."
        exit 1
    fi
else
    echo "Docker is already installed."
fi

# --- 2. PREPARE DIRECTORIES AND CERTIFICATES ---
echo "[+] Preparing directory structure at $BASE_DIR..."
# ساخت مجدد دایرکتوری‌ها
mkdir -p "$CERTS_DIR" "$DATA_DIR"

echo "[+] Writing default certificates (safeandroid.ir)..."
# توجه: محتوای گواهی‌ها بدون تغییر و بدون تورفتگی (Indentation) قرار داده شد.
cat > "$CERTS_DIR/fullchain.pem" << 'EOF'
-----BEGIN CERTIFICATE-----
MIIDpDCCAymgAwIBAgISBtNt3IyKd86uKHTzZ1EzOpPJMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
NzAeFw0yNTEyMDcxOTQ1NDNaFw0yNjAzMDcxOTQ1NDJaMBkxFzAVBgNVBAMTDnNh
ZmVhbmRyb2lkLmlyMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEgh1p+L7XOZQU
EerPenriIGfzfQw/vLzq2Dm/PP/nhBSyqjBuryt/a6Shy0bErocP6Oov2AhkjE5z
HPpQ1rN56KOCAjYwggIyMA4GA1UdDwEB/wQEAwIHgDAdBgNVHSUEFjAUBggrBgEF
BQcDAQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUSxIbMCMe1edN
I1CD6u9OgkXyUJAwHwYDVR0jBBgwFoAUrkie3IcdRKBv2qLlYHQEeMKcAIAwMgYI
KwYBBQUHAQEEJjAkMCIGCCsGAQUFBzAChhZodHRwOi8vZTcuaS5sZW5jci5vcmcv
MCsGA1UdEQQkMCKCECouc2FmZWFuZHJvaWQuaXKCDnNhZmVhbmRyb2lkLmlyMBMG
A1UdIAQMMAowCAYGZ4EMAQIBMC0GA1UdHwQmMCQwIqAgoB6GHGh0dHA6Ly9lNy5j
LmxlbmNyLm9yZy83NC5jcmwwggEMBgorBgEEAdZ5AgQCBIH9BIH6APgAfgBxfpXz
wjiKbbHjhEk9MeFaqWIIdi1CAOAFDNBntaZh4gAAAZr6jswMAAgAAAUAA5LmFQQD
AEcwRQIgV0t16ExzTvnK5g34HavCRkfG04WvMewYPdVd0uWLyuoCIQCW8HzOct5j
fPMESvMAR0KtB9ERQ9p8iFwT2v+w44/9/gB2ANFuqaVoB35mNaA/N6XdvAOlPEES
FNSIGPXpMbMjy5UEAAABmvqOzKMAAAQDAEcwRQIhAPY1QypryqvL5aqo1DRcKN4V
LeRTIG6KPpNToe9Ej1b1AiAODebZgap90rQw1zFrkZ3S/O9GnmQUCLeabZUsAKS9
jTAKBggqhkjOPQQDAwNpADBmAjEA8HohuLRu8wTFVMB30202xvXChODVeSHDLYvU
iGl6TX0cGxOzf7T1LYbFrGkWkKD+AjEAhLnR4K3qXTE2RDKHotYj1mv79uV6oxsD
tJ2ikIZX6AyD5LSKGN5PzG3pEe7uIrN1
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIEVzCCAj+gAwIBAgIRAKp18eYrjwoiCWbTi7/UuqEwDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjQwMzEzMDAwMDAw
WhcNMjcwMzEyMjM1OTU5WjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCRTcwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAARB6AST
CFh/vjcwDMCgQer+VtqEkz7JANurZxLP+U9TCeioL6sp5Z8VRvRbYk4P1INBmbef
QHJFHCxcSjKmwtvGBWpl/9ra8HW0QDsUaJW2qOJqceJ0ZVFT3hbUHifBM/2jgfgw
gfUwDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSuSJ7chx1EoG/aouVgdAR4
wpwAgDAfBgNVHSMEGDAWgBR5tFnme7bl5AFzgAiIyBpY9umbbjAyBggrBgEFBQcB
AQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly94MS5pLmxlbmNyLm9yZy8wEwYDVR0g
BAwwCjAIBgZngQwBAgEwJwYDVR0fBCAwHjAcoBqgGIYWaHR0cDovL3gxLmMubGVu
Y3Iub3JnLzANBgkqhkiG9w0BAQsFAAOCAgEAjx66fDdLk5ywFn3CzA1w1qfylHUD
aEf0QZpXcJseddJGSfbUUOvbNR9N/QQ16K1lXl4VFyhmGXDT5Kdfcr0RvIIVrNxF
h4lqHtRRCP6RBRstqbZ2zURgqakn/Xip0iaQL0IdfHBZr396FgknniRYFckKORPG
yM3QKnd66gtMst8I5nkRQlAg/Jb+Gc3egIvuGKWboE1G89NTsN9LTDD3PLj0dUMr
OIuqVjLB8pEC6yk9enrlrqjXQgkLEYhXzq7dLafv5Vkig6Gl0nuuqjqfp0Q1bi1o
yVNAlXe6aUXw92CcghC9bNsKEO1+M52YY5+ofIXlS/SEQbvVYYBLZ5yeiglV6t3S
M6H+vTG0aP9YHzLn/KVOHzGQfXDP7qM5tkf+7diZe7o2fw6O7IvN6fsQXEQQj8TJ
UXJxv2/uJhcuy/tSDgXwHM8Uk34WNbRT7zGTGkQRX0gsbjAea/jYAoWv0ZvQRwpq
Pe79D/i7Cep8qWnA+7AE/3B3S/3dEEYmc0lpe1366A/6GEgk3ktr9PEoQrLChs6I
tu3wnNLB2euC8IKGLQFpGtOO/2/hiAKjyajaBP25w1jF0Wl8Bbqne3uZ2q1GyPFJ
YRmT7/OXpmOH/FVLtwS+8ng1cAmpCujPwteJZNcDG0sF2n/sc0+SQf49fdyUK0ty
+VUwFj9tmWxyR/M=
-----END CERTIFICATE-----
EOF

cat > "$CERTS_DIR/key.pem" << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEICgh6fO30Vgh1Uw/zjkf5NnlqufRGqzD2e0pwh5t2VPmoAoGCCqGSM49
AwEHoUQDQgAEgh1p+L7XOZQUEerPenriIGfzfQw/vLzq2Dm/PP/nhBSyqjBuryt/
a6Shy0bErocP6Oov2AhkjE5zHPpQ1rN56A==
-----END EC PRIVATE KEY-----
EOF

cat > "$BASE_DIR/client.pem" << 'EOF'
-----BEGIN CERTIFICATE-----
MIIBXTCCAQOgAwIBAgIUcPaQcFbLDpYia0MJW6YobrbocQwwCgYIKoZIzj0EAwIw
ADAeFw0yNTEyMDcwNTM0NDlaFw0zNTEyMDUwNTM0NDlaMAAwWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAARjpE6/LVXFEZRpjR4uTUrU1/wwNAZl+SpInqN+v4sedzln
3LcKzwZGPavJIRexfVaKyBj+V7AM9CEdfvW46BLio1swWTAMBgNVHRMBAf8EAjAA
MAsGA1UdDwQEAwIFoDAdBgNVHQ4EFgQUZK7DrfWf95Ne3FIo/phD5rW1bk0wHQYD
VR0lBBYwFAYIKwYBBQUHAwEGCCsGAQUFBwMCMAoGCCqGSM49BAMCA0gAMEUCIGaI
vnHR17qb8C/gBQgyIjhc2+LQ85qE7HN1XdjYT7YCAiEA2WXGcHrALXVT3Xervagx
TWm06WQe3lX0p/SoUm06tr0=
-----END CERTIFICATE-----
EOF

# --- 3. CLONE REPO AND START CONTAINER ---
echo "[+] Downloading initial config from GitHub..."
if ! curl -L "$DEFAULT_XRAY_CONFIG_URL" > "$CONFIG_FILE"; then
    echo "❌ Error: Failed to download initial config file. Exiting."
    exit 1
fi

echo "[+] Preparing project directory at: $INSTALL_DIR"
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory '$INSTALL_DIR' already exists. Cleaning up old files..."
    rm -rf "$INSTALL_DIR"
fi

if ! git clone https://github.com/marzneshin/marznode "$INSTALL_DIR"; then
    echo "❌ Error: Failed to clone MarzNode repository. Exiting."
    exit 1
fi

cd "$INSTALL_DIR"

echo "[+] Configuring docker-compose.yml..."
# تزریق متغیرها و تنظیم مسیرها
sed -i "
  /^\s*environment:/a \ \ \ \ \ \ SERVICE_PORT: \"$SERVICE_PORT\"\n\ \ \ \ \ \ INSECURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE_INTERVAL: \"5\"
  s|/var/lib/marznode|$BASE_DIR|g
" "$COMPOSE_FILE"

echo "[+] Starting MarzNode container ($PROJECT_NAME)..."
if ! docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d; then
    echo "❌ Error: Failed to start Docker container. Exiting."
    exit 1
fi
cd "$HOME"

# --- 4. INSTALL WARP (OPTIONAL) ---
read -r -p "Do you want to install and configure WARP? [y/N]: " INSTALL_WARP
if [[ "$INSTALL_WARP" =~ ^[Yy]$ ]]; then
    echo "[+] Installing and configuring wgcf..."

    # بررسی نصب بودن wgcf و نصب آن
    if ! command -v wgcf &> /dev/null; then
        WGCF_FILE="wgcf_2.2.27_linux_amd64"
        wget -q https://github.com/ViRb3/wgcf/releases/download/v2.2.27/"$WGCF_FILE"
        chmod +x "$WGCF_FILE"
        mv "$WGCF_FILE" /usr/bin/wgcf
    fi

    wgcf register --accept-tos || echo "⚠️ Warning: wgcf registration failed, attempting to continue."
    wgcf generate

    apt update -qq && apt install -y wireguard-dkms wireguard-tools resolvconf

    # اگر فایل کانفیگ wgcf موجود بود، ادامه بده
    if [ -f "wgcf-profile.conf" ]; then
        sed -i '/MTU = 1280/a Table = off' wgcf-profile.conf
        mkdir -p /etc/wireguard
        cp wgcf-profile.conf /etc/wireguard/warp.conf
        systemctl enable --now wg-quick@warp
    else
        echo "⚠️ Warning: wgcf-profile.conf not found. WARP setup skipped."
    fi
else
    echo "[!] Skipping WARP installation."
fi

# --- 5. UPDATE XRAY CORE ---
echo "[+] Updating Xray binary to v$XRAY_VERSION..."

cd "$INSTALL_DIR"
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" stop

XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/$XRAY_ZIP"

cd "$DATA_DIR"
apt update -qq && apt install -y unzip wget
rm -f "$XRAY_BIN" # حذف باینری قبلی

echo "Downloading Xray from $XRAY_URL"
if ! wget -O "$XRAY_ZIP" "$XRAY_URL"; then
    echo "❌ Error: Failed to download Xray v$XRAY_VERSION. Check version number. Exiting."
    exit 1
fi

unzip -o "$XRAY_ZIP"
rm "$XRAY_ZIP"
cp "$DATA_DIR/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

# تنظیم مجدد فایل کامپوز برای باینری جدید
cd "$INSTALL_DIR"
sed -i '/XRAY_EXECUTABLE_PATH:/d' "$COMPOSE_FILE"
sed -i '/XRAY_ASSETS_PATH:/d' "$COMPOSE_FILE"

awk -v binary="$XRAY_BIN" -v assets="$DATA_DIR" '
/environment:/ {
  print;
  print "      XRAY_EXECUTABLE_PATH: \"" binary "\"";
  print "      XRAY_ASSETS_PATH: \"" assets "\"";
  next
}
{ print }
' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"

echo "[+] Restarting container with new Xray binary..."
if ! docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d; then
    echo "❌ Error: Failed to restart Docker container after Xray update. Exiting."
    exit 1
fi
cd "$HOME"

# --- 6. APPLY BBR OPTIMIZATION ---
echo "[+] Applying BBR optimization..."
apt-get -o Acquire::ForceIPv4=true update -qq
apt-get -o Acquire::ForceIPv4=true install -y sudo curl jq

# بررسی URL BBR قبل از اجرا
BBR_SCRIPT_URL="https://raw.githubusercontent.com/develfishere/Linux_NetworkOptimizer/main/bbr.sh"
if ! bash <(curl -Ls --ipv4 "$BBR_SCRIPT_URL"); then
    echo "⚠️ Warning: BBR script execution failed, but continuing installation."
fi

# --- 7. GENERATE AND INJECT REALITY KEYS ---
echo "[+] Waiting 5 seconds for Xray to initialize for key generation..."
sleep 5

echo "[+] Generating Reality keys..."
KEYS=$(docker exec "$CONTAINER_NAME" "$XRAY_BIN" x25519) # استفاده از باینری جدید در کانتینر

PRIVATE_KEY=$(echo "$KEYS" | grep 'Private key:' | awk '{print $3}' | tr -d '\r')
PUBLIC_KEY=$(echo "$KEYS" | grep 'Public key:' | awk '{print $3}' | tr -d '\r')
SHORT_ID=$(openssl rand -hex 8)

if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: Failed to generate Reality keys. Check container logs: docker logs $CONTAINER_NAME. Exiting."
    exit 1
fi

echo "----------------------------------------"
echo "🔑 Public Key: $PUBLIC_KEY"
echo "🔑 Private Key: $PRIVATE_KEY"
echo "🔒 Short ID: $SHORT_ID"
echo "----------------------------------------"

echo "[+] Overwriting config file with generated keys at: $CONFIG_FILE"

# نکته: مسیر certificates در JSON به متغیر BASE_DIR وابسته شد
cat > "$CONFIG_FILE" <<EOF
{
    "log": {
        "loglevel": "warning"
    },
    "dns": {
        "servers": [
            "https+local://1.1.1.1/dns-query",
            "https+local://1.0.0.1/dns-query"
        ]
    },
    "routing": {
        "domainStrategy": "IPIfNonMatch",
        "rules": [
            {
                "type": "field",
                "outboundTag": "warp",
                "ip": [
                    "geoip:ir"
                ]
            },
            {
                "type": "field",
                "ip": [
                    "geoip:private"
                ],
                "outboundTag": "block"
            }
        ]
    },
    "inbounds": [
        {
            "tag": "CDN",
            "listen": "0.0.0.0",
            "port": 443,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {},
                "security": "tls",
                "tlsSettings": {
                    "serverName": "",
                    "certificates": [
                        {
                            "ocspStapling": 3600,
                            "certificateFile": "$CERTS_DIR/fullchain.pem",
                            "keyFile": "$CERTS_DIR/key.pem"
                        }
                    ],
                    "minVersion": "1.1",
                    "cipherSuites": "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256:TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384:TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {
            "tag": "4tun",
            "listen": "0.0.0.0",
            "port": 4545,
            "protocol": "vmess",
            "settings": {
                "clients": []
            },
            "streamSettings": {
                "network": "grpc",
                "security": "none",
                "grpcSettings": {
                    "serviceName": "odin"
                }
            },
            "sniffing": {
                "enabled": true,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        },
        {
            "tag": "Reality",
            "listen": "0.0.0.0",
            "port": 8890,
            "protocol": "vless",
            "settings": {
                "clients": [],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "tcpSettings": {},
                "security": "reality",
                "realitySettings": {
                    "show": false,
                    "dest": "mdundo.com:443",
                    "xver": 0,
                    "serverNames": [
                        "refersion.com"
                    ],
                    "privateKey": "$PRIVATE_KEY",
                    "publicKey": "$PUBLIC_KEY",
                    "shortIds": [
                        "$SHORT_ID"
                    ]
                }
            },
            "sniffing": {
                "enabled": false,
                "destOverride": [
                    "http",
                    "tls"
                ]
            }
        }
        ],
    "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF

echo "[+] Applying new config (Restarting Container)..."
if ! docker restart "$CONTAINER_NAME"; then
    echo "❌ Error: Failed to restart container. Check status with: docker ps. Exiting."
    exit 1
fi

echo ""
echo "===================================================="
echo "✅ INSTALLATION SUCCESSFUL"
echo "===================================================="
echo "Project Name: $PROJECT_NAME"
echo "Xray Config File:  $CONFIG_FILE"
echo "Container Name: $CONTAINER_NAME"
echo "===================================================="
