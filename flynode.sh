#!/bin/bash

# توقف اسکریپت در صورت بروز هرگونه خطا
set -e

# --- دریافت ورودی‌ها ---
read -p "Enter service port [default: 89101]: " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-59101}

read -p "Enter XRAY version [default: 25.6.8]: " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-25.6.8}

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

cat > "$BASE_DIR/client.pem" << 'EOF'
-----BEGIN CERTIFICATE-----
MIIEnDCCAoQCAQAwDQYJKoZIhvcNAQENBQAwEzERMA8GA1UEAwwIR296YXJnYWgw
IBcNMjUwMjI0MTczNzMwWhgPMjEyNTAxMzExNzM3MzBaMBMxETAPBgNVBAMMCEdv
emFyZ2FoMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA2XKY68YElXG1
540Hyj7MVt5WJ5/mWdBD4vISX0/GWr0XkKpLTw8l/jeMSZdtVt76PJlAXajeKq6/
BXiWT2jPUoEtEhHoxNxSHwhRqkcC8EBgPwmyxiPTGs4JVX1n2IKekR2Tb3KFUHBj
ldz2uNrklpiO/mTDvEf5qeLze2/dBnyuZT45KpF/HFQB5KJYcOeStL0n5kThLsvk
lyLEnCDP6ma2zGgfLKldcCjM2w55CGH0Ngnmf3+YZEiwjih98bB9EDqFe+f3FL35
AjMlvOhH0xuiVFs2ujr72eC1CRGQYUB1BddUUFzKDSxRP+XUF74WdlNJcrVYe/XJ
/omFkSMek1sMJQDDCsqMO0Fu/UeyYOP/BVtdAmcYj3xFzGtOMu9eHSjHbG23W1sg
mwZ24acv7wzKW9JStu563Gc5DFQh29801ySCwZJ3vb0Hn7jdG8Xl5DlOKv7GJpO8
z/UttAbdhLiPTj/dg1TXB/1bZQbV1J4YSNklk9jRjgX5JJ1dGmygsTT8oi3Mvab0
VlMF5C/NvRRS5yCcPeLWKr/KVPq3K9SsiZ5j174RT3IJF8Zj2XSOY7onGq8XThQj
3Z4qgQXmDvy/vPtI3Z6u9s8J3tHWLQqqVKRDALL1u23+fuo50yAc5bLLN846pU5M
+5lAnMsPalOI/AII13D/JkEFiJRIN6MCAwEAATANBgkqhkiG9w0BAQ0FAAOCAgEA
DZOGa36Qzw+tHd1jxg8D/hp9CX4c6VFeWCOZBgQEVuO0NOutzcBJbJ1Oxyx0jdAn
irVFEvWldSVL3nr0siwe9HZRgGFNFqqNR30AtanR67TvjTpWuXYB50UOu1T3O6Qd
8rqquvm0gKDDQXsVJGjTE3Ifft12kP8MwyUAiDCBgSrqeWZn/E9MdEsZzW8m7L6m
/42nA1c1CsOfPXoOr2Nj00Lnvqf63HtMUYPb36SAaQaWDqOeReLy/7+tdheHPLgI
q0LTxxYqqZVbvWPkz9deRkNOtBO2LtG+Ev9FoFh9JMARhAkhWY9q1iD1JNuRHC0F
WTFHRGnNqAdPS+TWHdopgOwT3EE2EN245enHo2ekB9Y1JaRIYyV1f1pPRtCS8ciq
N9vEJhpkaCH66Ue4kXW2dLwy0nTW8pmCSEBA/pnHcXWBBGmejLsw4sJhhGnPBwTH
QPiIMac7/vR08P8Akf8VXVDUBUo4Df+3fTLt6ztFQInC4An6Nk6WREkGrAJZ3H41
o9aMSncMP+RCQvR3YmcrvkxSR6/0ONLqwqg24TpNwjep3utgGDIG+P8yrtmKCU26
inUT+ZqP+z4zp653zrklVb0LT1hNe7nFtEQ+bA/hNuXEVpimKdzNEQw4yTTEX0+d
PUxV2UWCo6B4ewcKMtECSzoumBlnR355b/4Q6n5STnw=
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
                "outboundTag": "warp",
                "domain": [
                    "tld-ir"
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
