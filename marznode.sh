#!/bin/bash

set -e

# Ask for input
read -p "Enter service port [default: 59101]: " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-59101}

read -p "Enter XRAY version [default: 25.3.6]: " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-25.3.6}

# --- بخش جدید برای پرسیدن نام پروژه ---
# این نام به عنوان پیشوند برای نام کانتینر استفاده خواهد شد.
read -p "Enter MarzNode project name [default: marznode]: " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-marznode}
# ---------------------------------------

echo "[+] Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "[+] Setting up MarzNode directories and certificates..."
mkdir -p /var/lib/marznode/certs/

# ... (بقیه قسمت‌های کپی کردن فایل‌های گواهی و کلیدها ثابت مانده است)
# ... (Cat commands for fullchain.pem, key.pem, client.pem - Omitted for brevity)

cat > /var/lib/marznode/certs/fullchain.pem << 'EOF'
-----BEGIN CERTIFICATE-----
MIIELTCCA7OgAwIBAgISBmwRag3eSg9lXPMzVpI2xsJmMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
ODAeFw0yNTEyMDMwNzA1NDVaFw0yNjAzMDMwNzA1NDRaMBgxFjAUBgNVBAMTDWJy
aW1saXNraS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARk+tHJCcDsXjNB
VQH4HF5dUSVUavKOjCVsRNf8pov67evx3atJZO0wfZ8GsCyaVIdMpTSQndI/4Q6n
s9h7GWXjo4ICwTCCAr0wDgYDVR0PAQH/BAQDAgeAMB0GA1UdJQQWMBQGCCsGAQUF
BwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBQ80J2wWQMmy8dx
sz74QpS5SMP/fTAfBgNVHSMEGDAWgBSPDROi9i5+0VBsMxg4XVmOI3KRyjAyBggr
BgEFBQcBAQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly9lOC5pLmxlbmNyLm9yZy8w
gbMGA1UdEQSBqzCBqIIPKi5icmltbGlza2kuY29tgg0qLmN1dGVtdWdzLmlygg0q
Lm9kaW5zc2wueHl6gg8qLm9uZGVzbWlsaW0uZnKCFyouemhvbmd5YW5nLXRlbGVj
b20uY29tgg1icmltbGlza2kuY29tggtjdXRlbXVncy5pcoILb2RpbnNzbC54eXqC
DW9uZGVzbWlsaW0uZnKCFXpob25neWFuZy10ZWxlY29tLmNvbTATBgNVHSAEDDAK
MAgGBmeBDAECATAuBgNVHR8EJzAlMCOgIaAfhh1odHRwOi8vZTguYy5sZW5jci5v
cmcvMTAzLmNybDCCAQ0GCisGAQQB1nkCBAIEgf4EgfsA+QB2ANFuqaVoB35mNaA/
N6XdvAOlPEESFNSIGPXpMbMjy5UEAAABmuM9mEYAAAQDAEcwRQIgMbZ3rqkZZfth
V7q3zgcjfz717a/9GW7MIufkEoGjuioCIQDESuQvkdN6rNp6mT0HI1egTgbval1t
kO3F6grb/jIK8AB/AOMjjfKNoojgquCs8PqQyYXwtr/10qUnsAH8HERYxLboAAAB
muM9mgsACAAABQAnQiGEBAMASDBGAiEAkEdmL316c4MpkIEk51vfHMyD3yWJ2PKg
+LeMhAYgN1cCIQCeDbFq9bBVerLulse1bvn4wrm3uhfbDBKbzlLDJQKTDDAKBggq
hkjOPQQDAwNoADBlAjEAosNKSCKMr4/kt6Bp1cdJBYl/LcX2AnWSXrA1mB6zD6lA
FHqq0JmmerAzIRfwDQhQAjB9Gbsmb7BUPqhLds5rR8ejLps7ijN1sAq0mwX53WJJ
mP/Bge0cQ9+eSFWgJ0Dm3uQ=
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

cat > /var/lib/marznode/certs/key.pem << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIEf080v6t26xqaxtopYWtNl6dtoU2UMuEZ35xqO3uGwZoAoGCCqGSM49
AwEHoUQDQgAEZPrRyQnA7F4zQVUB+BxeXVElVGryjowlbETX/KaL+u3r8d2rSWTt
MH2fBrAsmlSHTKU0kJ3SP+EOp7PYexll4w==
-----END EC PRIVATE KEY-----
EOF

cat > /var/lib/marznode/client.pem << 'EOF'
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


echo "[+] Downloading MarzNode configuration..."
curl -L https://github.com/marzneshin/marznode/raw/master/xray_config.json > /var/lib/marznode/xray_config.json

echo "[+] Cloning MarzNode repo..."
git clone https://github.com/marzneshin/marznode
cd marznode

echo "[+] Injecting service port and environment variables..."
sed -i "/^\s*environment:/a \ \ \ \ \ \ SERVICE_PORT: \"$SERVICE_PORT\"\n\ \ \ \ \ \ INSECURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE: \"True\"\n\ \ \ \ \ \ XRAY_RESTART_ON_FAILURE_INTERVAL: \"5\"" ./compose.yml

echo "[+] Starting MarzNode Docker container with project name '$PROJECT_NAME'..."
# --- تغییر در اینجاست: استفاده از -p (یا --project-name) برای تعیین نام پروژه ---
docker compose -f ./compose.yml -p "$PROJECT_NAME" up -d
cd

# ... (بقیه قسمت‌های WARP و تنظیم DNS ثابت مانده است)

# Ask if WARP should be installed
read -p "Do you want to install and configure WARP? [y/N]: " INSTALL_WARP
if [[ "$INSTALL_WARP" =~ ^[Yy]$ ]]; then
  echo "[+] Installing and configuring wgcf..."
  wget https://github.com/ViRb3/wgcf/releases/download/v2.2.27/wgcf_2.2.27_linux_amd64
  chmod +x wgcf_2.2.27_linux_amd64
  mv wgcf_2.2.27_linux_amd64 /usr/bin/wgcf
  wgcf register || true
  wgcf generate

  apt update && apt install -y wireguard-dkms wireguard-tools resolvconf
  sed -i '/MTU = 1280/a Table = off' ~/wgcf-profile.conf
  cp ~/wgcf-profile.conf /etc/wireguard/warp.conf
  systemctl enable wg-quick@warp
else
  echo "[!] Skipping WARP installation."
fi

echo "[+] Configuring Docker DNS..."
echo '{"dns": ["1.1.1.1", "1.0.0.1"]}' | tee /etc/docker/daemon.json
systemctl restart docker
# نام کانتینر برای ری‌استارت از روی PROJECT_NAME تغییر کرده است
docker restart "$PROJECT_NAME-marznode-1"

echo "[+] Fetching Xray keys and installing version $XRAY_VERSION..."
docker exec "$PROJECT_NAME-marznode-1" xray x25519
openssl rand -hex 8

echo "[+] Updating Xray binary..."
DATA_DIR="/var/lib/marznode/data"
XRAY_BIN="/var/lib/marznode/xray"
COMPOSE_FILE="$HOME/marznode/compose.yml"
XRAY_ZIP="Xray-linux-64.zip"
XRAY_URL="https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/$XRAY_ZIP"

mkdir -p "$DATA_DIR"
cd "$DATA_DIR"
apt update && apt install -y unzip
wget "$XRAY_URL"
unzip "$XRAY_ZIP"
rm "$XRAY_ZIP"
cp "$DATA_DIR/xray" "$XRAY_BIN"
chmod +x "$XRAY_BIN"

sed -i '/XRAY_EXECUTABLE_PATH:/d' "$COMPOSE_FILE"
sed -i '/XRAY_ASSETS_PATH:/d' "$COMPOSE_FILE"
awk '
/environment:/ {
  print;
  print "      XRAY_EXECUTABLE_PATH: \"/var/lib/marznode/xray\"";
  print "      XRAY_ASSETS_PATH: \"/var/lib/marznode/data\"";
  next
}
{ print }
' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"

cd "$HOME/marznode"
# --- تغییر در اینجاست: استفاده از -p برای داون کردن سرویس با نام پروژه جدید ---
docker compose -f ./compose.yml -p "$PROJECT_NAME" down
# --- تغییر در اینجاست: استفاده از -p برای بالا آوردن سرویس با نام پروژه جدید ---
docker compose -f ./compose.yml -p "$PROJECT_NAME" up -d
cd

echo "[+] Applying Linux network optimizations..."
apt-get -o Acquire::ForceIPv4=true update
apt-get -o Acquire::ForceIPv4=true install -y sudo curl jq
bash <(curl -Ls --ipv4 https://raw.githubusercontent.com/develfishere/Linux_NetworkOptimizer/main/bbr.sh)

echo ""
echo "✅ Installation completed successfully!"
echo "----------------------------------------"
echo "SERVICE_PORT: $SERVICE_PORT"
echo "XRAY_VERSION: $XRAY_VERSION"
echo "PROJECT_NAME: $PROJECT_NAME"
echo ""
echo "🔑 X25519 Public/Private Key Pair:"
docker exec "$PROJECT_NAME-marznode-1" xray x25519
echo ""
echo "🔒 Random Hex (for UUID or other use):"
openssl rand -hex 8
echo "----------------------------------------"

echo "[+] Generating Reality keys..."
KEYS=$(docker exec "$PROJECT_NAME-marznode-1" xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep 'Private key:' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep 'Public key:' | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)

echo "[+] Writing Xray config with injected keys..."

# ... (بقیه قسمت‌های نوشتن فایل xray_config.json ثابت مانده است)
# ... (Cat command for xray_config.json - Omitted for brevity)

cat > /var/lib/marznode/xray_config.json <<EOF
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
                    "domain:0g.ai",
                    "domain:9anime.me",
                    "domain:adbtc.top",
                    "domain:adobe.com",
                    "domain:ai.com",
                    "domain:alfafrens.com",
                    "domain:alldatasheet.com",
                    "domain:alliedmods.net",
                    "domain:allora.network",
                    "domain:angle.money",
                    "domain:app-measurment.com",
                    "domain:aptosfoundation.org",
                    "domain:axieinfinity.com",
                    "domain:babylonchain.io",
                    "domain:battle.net",
                    "domain:beamable.network",
                    "domain:behance.net",
                    "domain:berachain.com",
                    "domain:binance.org",
                    "domain:bitavatar.io",
                    "domain:bscscan.com",
                    "domain:caldera.dev",
                    "domain:caldera.xyz",
                    "domain:chainbase.com",
                    "domain:civic.com",
                    "domain:clubhouse.com",
                    "domain:clutchplay.ai",
                    "domain:codefi.network",
                    "domain:coingecko.com",
                    "domain:cookie.community",
                    "domain:cryptocompare.com",
                    "domain:dcounter.space",
                    "domain:defisaver.com",
                    "domain:developer.mozilla.org",
                    "domain:dimension.xyz",
                    "domain:drip.haus",
                    "domain:eclipse.xyz",
                    "domain:eigenfoundation.org",
                    "domain:ethermail.io",
                    "domain:etherpillar.org",
                    "domain:etherscan.io",
                    "domain:evolution-x.org",
                    "domain:flaticon.com",
                    "domain:flutter.dev",
                    "domain:freepik.com",
                    "domain:galaxy.eco",
                    "domain:gamebanana.com",
                    "domain:gamic.app",
                    "domain:getgrass.io",
                    "domain:giglio.com",
                    "domain:gitcoin.co",
                    "domain:gleam.io",
                    "domain:gmx.io",
                    "domain:guild.xyz",
                    "domain:gv2.com",
                    "domain:herokuapp.com",
                    "domain:homedepot.com",
                    "domain:illuvium.io",
                    "domain:immutable.com",
                    "domain:infura.io",
                    "domain:initia.xyz",
                    "domain:instagram.com",
                    "domain:intract.io",
                    "domain:iog.net",
                    "domain:ip.gs",
                    "domain:ipinfo.io",
                    "domain:iq.space",
                    "domain:jumper.exchange",
                    "domain:kenvyra.xyz",
                    "domain:kinto.xyz",
                    "domain:kmplayer.com",
                    "domain:lagrangefoundation.org",
                    "domain:layer3.xyz",
                    "domain:layeredge.foundation",
                    "domain:livechart.me",
                    "domain:lookmovie2.to",
                    "domain:lumoz.org",
                    "domain:mantra.zone",
                    "domain:metamask.io",
                    "domain:mintpad.co",
                    "domain:mql5.com",
                    "domain:myanimelist.net",
                    "domain:myshell.ai",
                    "domain:namada.net",
                    "domain:nfprompt.io",
                    "domain:nillion.com",
                    "domain:ntp.org",
                    "domain:nubit.org",
                    "domain:okx.com",
                    "domain:omegle.com",
                    "domain:openai.com",
                    "domain:openledger.xyz",
                    "domain:over.network",
                    "domain:pagespeed.web.dev",
                    "domain:passport.gitcoin.co",
                    "domain:pixelexperience.org",
                    "domain:pixelos.net",
                    "domain:plumenetwork.xyz",
                    "domain:polygon-rpc.com",
                    "domain:qna3.ai",
                    "domain:remini.com",
                    "domain:saharalabs.ai",
                    "domain:sandbox.game",
                    "domain:segment.io",
                    "domain:sending.me",
                    "domain:signetfaucet.com",
                    "domain:snapchat.com",
                    "domain:sonic.game",
                    "domain:sonorus.network",
                    "domain:sourcemod.net",
                    "domain:spark-os.live",
                    "domain:spectrallabs.xyz",
                    "domain:spotify.com",
                    "domain:story.foundation",
                    "domain:sunriselayer.io",
                    "domain:superrare.com",
                    "domain:synonai.net",
                    "domain:thadfiscella.com",
                    "domain:theblock.co",
                    "domain:tiktok.com",
                    "domain:trustalabs.ai",
                    "domain:tunetank.com",
                    "domain:unity3d.com",
                    "domain:universalx.app",
                    "domain:venom.network",
                    "domain:viem.sh",
                    "domain:walletconnect.com",
                    "domain:walrus.site",
                    "domain:warpcast.com",
                    "domain:xally.ai",
                    "domain:xda-developers.com",
                    "domain:yooldo.gg",
                    "domain:zkbridge.com",
                    "domain:zknation.io",
                    "domain:zksync.io",
                    "domain:zora.co",
                    "domain:zora.energy",
                    "geosite:bytedance",
                    "geosite:google",
                    "geosite:netflix",
                    "geosite:nvidia",
                    "geosite:openai",
                    "geosite:reddit",
                    "geosite:spotify",
                    "geosite:tiktok",
                    "geosite:unity",
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
            "tag": "C4",
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
            "tag": "C1",
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
