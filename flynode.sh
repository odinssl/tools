#!/bin/bash

# توقف اسکریپت در صورت بروز هرگونه خطا
set -e

# --- دریافت ورودی‌ها ---
read -p "Enter service port [default: 59101]: " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-59101}

read -p "Enter XRAY version [default: 25.3.6]: " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-25.3.6}

read -p "Enter MarzNode project name [default: marznode]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-marznode}

# --- تعریف مسیرهای حیاتی ---
# مسیر اصلی فایل‌های دیتا و کانفیگ بر اساس نام پروژه
BASE_DIR="/var/lib/$PROJECT_NAME"
CERTS_DIR="$BASE_DIR/certs"
DATA_DIR="$BASE_DIR/data"
XRAY_BIN="$BASE_DIR/xray"
CONFIG_FILE="$BASE_DIR/xray_config.json"
INSTALL_DIR="$HOME/$PROJECT_NAME"

echo "===================================================="
echo "   MARZNODE INSTALLATION STARTED"
echo "   Project: $PROJECT_NAME"
echo "   Config Path: $CONFIG_FILE"
echo "===================================================="

echo "[+] Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
else
    echo "Docker is already installed."
fi

echo "[+] Preparing directory structure at $BASE_DIR..."
# حذف و ساخت مجدد دایرکتوری‌ها برای جلوگیری از تداخل
mkdir -p "$CERTS_DIR"
mkdir -p "$DATA_DIR"

# --- نوشتن سرتیفیکیت‌ها ---
echo "[+] Writing certificates..."
cat > "$CERTS_DIR/fullchain.pem" << 'EOF'
-----BEGIN CERTIFICATE-----
MIIDmjCCAyGgAwIBAgISBRT/PM1cr7BiL8R3sBUfA07TMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
ODAeFw0yNTEyMTAwNjU3NDZaFw0yNjAzMTAwNjU3NDVaMBYxFDASBgNVBAMTC2Zs
eTR0ZWNoLmlyMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEv04t5lT8tgDPTaN2
F2l7/gljPTCwFUqXASqn8PUsaa+/2+6jQoslkYlq6Noo3cNeolgouMV0HMCLpAP3
pbaF9aOCAjEwggItMA4GA1UdDwEB/wQEAwIHgDAdBgNVHSUEFjAUBggrBgEFBQcD
AQYIKwYBBQUHAwIwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUfnMKqM0DLei9zgl0
lRldnrLiA5kwHwYDVR0jBBgwFoAUjw0TovYuftFQbDMYOF1ZjiNykcowMgYIKwYB
BQUHAQEEJjAkMCIGCCsGAQUFBzAChhZodHRwOi8vZTguaS5sZW5jci5vcmcvMCUG
A1UdEQQeMByCDSouZmx5NHRlY2guaXKCC2ZseTR0ZWNoLmlyMBMGA1UdIAQMMAow
CAYGZ4EMAQIBMC0GA1UdHwQmMCQwIqAgoB6GHGh0dHA6Ly9lOC5jLmxlbmNyLm9y
Zy84NC5jcmwwggENBgorBgEEAdZ5AgQCBIH+BIH7APkAfwClyXiSXVdGF4KHDdiJ
ZgtcVWSLfQBA8uwHaFHRiGkZ9wAAAZsHQsw+AAgAAAUAKvOJaAQDAEgwRgIhALvD
vC2pKVPR07ZemvdtmDubqFNPXi7JN3ZXH4qIvPzvAiEAk5CmtJjmxc7TJov7HT/6
3DAcSvMPBgxNoWC4bGBO4w8AdgAOV5S8866pPjMbLJkHs/eQ35vCPXEyJd0hqSWs
YcVOIQAAAZsHQtmlAAAEAwBHMEUCIQD5Bl9BhtBvOj3IEqyIrfEJ1QWsrLDzASnw
5tZxGc7VjQIgdq6D2LwJTaT981Fla315R7O+k7Av5UU2n1EsUGg7tcEwCgYIKoZI
zj0EAwMDZwAwZAIwHjmHD/SCJOHab8qGoAypDCdyKfO6y4GSndQ6O0U4dqjtqdyx
il5RBupzeYCL8+HMAjAJ165V27cnHbzr2vIAmlKY2l/aCVCTf8SzMfoMVyUj/1oZ
KGtiOEq8ubFTx+8yazQ=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEVjCCAj6gAwIBAgIQY5WTY8JOcIJxWRi/w9ftVjANBgkqhkiG9w0BAQsFADBP
MQswCQYDVQQGEwJVUzEpMCcGA1UEChMgSW50ZXJuZXQgU2VjdXJpdHkgUmVzZWFy
Y2ggR3JvdXAxFTATBgNVBAMTDElTUkcgUm9vdCBYMTAeFw0yNDAzMTMwMDAwMDBa
Fw0yNzAzMTIyMzU5NTlaMDIxCzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBF
bmNyeXB0MQswCQYDVQQDEwJFODB2MBAGByqGSM49AgEGBSuBBAAiA2IABNFl8l7c
S7QMApzSsvru6WyrOq44ofTUOTIzxULUzDMMNMchIJBwXOhiLxxxs0LXeb5GDcHb
R6EToMffgSZjO9SNHfY9gjMy9vQr5/WWOrQTZxh7az6NSNnq3u2ubT6HTKOB+DCB
9TAOBgNVHQ8BAf8EBAMCAYYwHQYDVR0lBBYwFAYIKwYBBQUHAwIGCCsGAQUFBwMB
MBIGA1UdEwEB/wQIMAYBAf8CAQAwHQYDVR0OBBYEFI8NE6L2Ln7RUGwzGDhdWY4j
cpHKMB8GA1UdIwQYMBaAFHm0WeZ7tuXkAXOACIjIGlj26ZtuMDIGCCsGAQUFBwEB
BCYwJDAiBggrBgEFBQcwAoYWaHR0cDovL3gxLmkubGVuY3Iub3JnLzATBgNVHSAE
DDAKMAgGBmeBDAECATAnBgNVHR8EIDAeMBygGqAYhhZodHRwOi8veDEuYy5sZW5j
ci5vcmcvMA0GCSqGSIb3DQEBCwUAA4ICAQBnE0hGINKsCYWi0Xx1ygxD5qihEjZ0
RI3tTZz1wuATH3ZwYPIp97kWEayanD1j0cDhIYzy4CkDo2jB8D5t0a6zZWzlr98d
AQFNh8uKJkIHdLShy+nUyeZxc5bNeMp1Lu0gSzE4McqfmNMvIpeiwWSYO9w82Ob8
otvXcO2JUYi3svHIWRm3+707DUbL51XMcY2iZdlCq4Wa9nbuk3WTU4gr6LY8MzVA
aDQG2+4U3eJ6qUF10bBnR1uuVyDYs9RhrwucRVnfuDj29CMLTsplM5f5wSV5hUpm
Uwp/vV7M4w4aGunt74koX71n4EdagCsL/Yk5+mAQU0+tue0JOfAV/R6t1k+Xk9s2
HMQFeoxppfzAVC04FdG9M+AC2JWxmFSt6BCuh3CEey3fE52Qrj9YM75rtvIjsm/1
Hl+u//Wqxnu1ZQ4jpa+VpuZiGOlWrqSP9eogdOhCGisnyewWJwRQOqK16wiGyZeR
xs/Bekw65vwSIaVkBruPiTfMOo0Zh4gVa8/qJgMbJbyrwwG97z/PRgmLKCDl8z3d
tA0Z7qq7fta0Gl24uyuB05dqI5J1LvAzKuWdIjT1tP8qCoxSE/xpix8hX2dt3h+/
jujUgFPFZ0EVZ0xSyBNRF3MboGZnYXFUxpNjTWPKpagDHJQmqrAcDmWJnMsFY3jS
u1igv3OefnWjSQ==
-----END CERTIFICATE-----
EOF

cat > "$CERTS_DIR/key.pem" << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKtLy1jL8xISdMWT6gS/H5crdgdJGTZMWQ15ZUEkBD+VoAoGCCqGSM49
AwEHoUQDQgAEv04t5lT8tgDPTaN2F2l7/gljPTCwFUqXASqn8PUsaa+/2+6jQosl
kYlq6Noo3cNeolgouMV0HMCLpAP3pbaF9Q==
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
TWm06WQe3lX0p+SoUm06tr0=
-----END CERTIFICATE-----
EOF

# --- دانلود کانفیگ اولیه ---
echo "[+] Downloading initial config..."
curl -L https://github.com/marzneshin/marznode/raw/master/xray_config.json > "$CONFIG_FILE"

# --- کلون کردن ریپو و مدیریت فایل‌های داکر ---
echo "[+] Preparing project directory at: $INSTALL_DIR"
if [ -d "$INSTALL_DIR" ]; then
    echo "Directory '$INSTALL_DIR' already exists. Cleaning up..."
    rm -rf "$INSTALL_DIR"
fi

git clone https://github.com/marzneshin/marznode "$INSTALL_DIR"
cd "$INSTALL_DIR"
COMPOSE_FILE="$INSTALL_DIR/compose.yml"

echo "[+] Configuring docker-compose.yml..."
# تزریق متغیرها
sed -i "/^\s*environment:/a \ \ \ \ \ \ SERVICE_PORT: \"$SERVICE_PORT\"\n\ \ \ \ \ \ INSECURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE_INTERVAL: \"5\"" "$COMPOSE_FILE"

# تغییر حیاتی: تغییر مسیر ولوم‌ها به مسیر پروژه فعلی
# این دستور باعث می‌شود داکر فایل‌های کانفیگ را از پوشه پروژه جدید بخواند
sed -i "s|/var/lib/marznode|$BASE_DIR|g" "$COMPOSE_FILE"

echo "[+] Starting MarzNode container ($PROJECT_NAME)..."
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
cd "$HOME"

# --- نصب WARP (اختیاری) ---
read -p "Do you want to install and configure WARP? [y/N]: " INSTALL_WARP
if [[ "$INSTALL_WARP" =~ ^[Yy]$ ]]; then
  echo "[+] Installing and configuring wgcf..."
  if [ ! -f /usr/bin/wgcf ]; then
      wget https://github.com/ViRb3/wgcf/releases/download/v2.2.27/wgcf_2.2.27_linux_amd64
      chmod +x wgcf_2.2.27_linux_amd64
      mv wgcf_2.2.27_linux_amd64 /usr/bin/wgcf
  fi
  
  wgcf register --accept-tos || true
  wgcf generate

  apt update && apt install -y wireguard-dkms wireguard-tools resolvconf
  sed -i '/MTU = 1280/a Table = off' wgcf-profile.conf
  mkdir -p /etc/wireguard
  cp wgcf-profile.conf /etc/wireguard/warp.conf
  systemctl enable --now wg-quick@warp
else
  echo "[!] Skipping WARP installation."
fi

echo "[+] Configuring Docker DNS..."
echo '{"dns": ["1.1.1.1", "1.0.0.1"]}' > /etc/docker/daemon.json
systemctl restart docker
docker restart "$PROJECT_NAME-marznode-1"

# --- آپدیت هسته Xray ---
echo "[+] Updating Xray binary to $XRAY_VERSION..."

# توقف کانتینر برای جلوگیری از ارور Text file busy
cd "$INSTALL_DIR"
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" stop

XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/$XRAY_ZIP"

mkdir -p "$DATA_DIR"
cd "$DATA_DIR"
apt update && apt install -y unzip wget
wget -O "$XRAY_ZIP" "$XRAY_URL"
unzip -o "$XRAY_ZIP"
rm "$XRAY_ZIP"
cp "$DATA_DIR/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

# تنظیم مجدد فایل کامپوز برای باینری جدید
sed -i '/XRAY_EXECUTABLE_PATH:/d' "$COMPOSE_FILE"
sed -i '/XRAY_ASSETS_PATH:/d' "$COMPOSE_FILE"

# استفاده از awk برای جایگذاری دقیق مسیرها
awk -v binary="$XRAY_BIN" -v assets="$DATA_DIR" '
/environment:/ {
  print;
  print "      XRAY_EXECUTABLE_PATH: \"" binary "\"";
  print "      XRAY_ASSETS_PATH: \"" assets "\"";
  next
}
{ print }
' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"

echo "[+] Starting container with new Xray binary..."
cd "$INSTALL_DIR"
docker compose -f "$COMPOSE_FILE" -p "$PROJECT_NAME" up -d
cd "$HOME"

# --- بهینه‌سازی شبکه ---
echo "[+] Applying BBR..."
apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true install -y sudo curl jq
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/develfishere/Linux_NetworkOptimizer/main/bbr.sh)

# --- تولید و تزریق کلیدها ---
echo "[+] Waiting for Xray to initialize..."
sleep 5

echo "[+] Generating Reality keys..."
KEYS=$(docker exec "$PROJECT_NAME-marznode-1" xray x25519)

# استخراج دقیق کلیدها
PRIVATE_KEY=$(echo "$KEYS" | grep 'Private key:' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep 'Public key:' | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)

# بررسی اینکه کلیدها خالی نباشند
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ Error: Failed to generate Private Key. Container might not be running correctly."
    exit 1
fi

echo "----------------------------------------"
echo "🔑 Public Key: $PUBLIC_KEY"
echo "🔑 Private Key: $PRIVATE_KEY"
echo "🔒 Short ID: $SHORT_ID"
echo "----------------------------------------"

echo "[+] Overwriting config at: $CONFIG_FILE"

# بازنویسی کامل فایل کانفیگ
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
                            "certificateFile": "/var/lib/marznode/certs/fullchain.pem",
                            "keyFile": "/var/lib/marznode/certs/key.pem"
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
            "tag": "Reality",
            "listen": "0.0.0.0",
            "port": 6690,
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
            "tag": "warp",
            "protocol": "freedom",
            "streamSettings": {
                "sockopt": {
                    "tcpFastOpen": true,
                    "interface": "warp"
                }
            }
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF

echo "[+] Applying new config (Restarting Container)..."
docker restart "$PROJECT_NAME-marznode-1"

echo ""
echo "===================================================="
echo "✅ INSTALLATION SUCCESSFUL"
echo "===================================================="
echo "Project Name: $PROJECT_NAME"
echo "Config File:  $CONFIG_FILE"
echo "===================================================="
