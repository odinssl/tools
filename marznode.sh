#!/bin/bash

set -e

# Ask for input
read -p "Enter service port [default: 59101]: " SERVICE_PORT
SERVICE_PORT=${SERVICE_PORT:-59101}

read -p "Enter XRAY version [default: 25.3.6]: " XRAY_VERSION
XRAY_VERSION=${XRAY_VERSION:-25.3.6}

echo "[+] Installing Docker..."
curl -fsSL https://get.docker.com | sh

echo "[+] Setting up MarzNode directories and certificates..."
mkdir -p /var/lib/marznode/certs/

cat > /var/lib/marznode/certs/fullchain.pem << 'EOF'
-----BEGIN CERTIFICATE-----
MIIDrzCCAzWgAwIBAgISBcq6UpIEWU9g9PnBlvPhOeJUMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
NzAeFw0yNTA5MDUxOTE5NTlaFw0yNTEyMDQxOTE5NThaMCAxHjAcBgNVBAMTFXpo
b25neWFuZy10ZWxlY29tLmNvbTBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABJSG
mLkkq5fexpB3lEOO73OOAlllzCuOJJYJax1QSGz0ZVfPJsNuTLxybzvpG7ANZfnJ
0UTJtktLip4w8bPPBvKjggI7MIICNzAOBgNVHQ8BAf8EBAMCB4AwHQYDVR0lBBYw
FAYIKwYBBQUHAwEGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHQYDVR0OBBYEFBva
W/tNjM9ZiPP0FjEj/BzeWsQHMB8GA1UdIwQYMBaAFK5IntyHHUSgb9qi5WB0BHjC
nACAMDIGCCsGAQUFBwEBBCYwJDAiBggrBgEFBQcwAoYWaHR0cDovL2U3LmkubGVu
Y3Iub3JnLzA5BgNVHREEMjAwghcqLnpob25neWFuZy10ZWxlY29tLmNvbYIVemhv
bmd5YW5nLXRlbGVjb20uY29tMBMGA1UdIAQMMAowCAYGZ4EMAQIBMC0GA1UdHwQm
MCQwIqAgoB6GHGh0dHA6Ly9lNy5jLmxlbmNyLm9yZy84NS5jcmwwggEDBgorBgEE
AdZ5AgQCBIH0BIHxAO8AdgDM+w9qhXEJZf6Vm1PO6bJ8IumFXA2XjbapflTA/kwN
sAAAAZkbh8/PAAAEAwBHMEUCIAFAfP1mGUAkY7Rtb+j5y+tsvsA4aqAK/qmjdgtW
TXytAiEAjlphnbFm9y2ax2U5POTFb13RuJh7DEddqJJwiRS4WdEAdQCkQsUGSWBh
VI8P1Oqc+3otJkVNh6l/L99FWfYnTzqEVAAAAZkbh9d4AAAEAwBGMEQCIBbcbLKR
YbGCjUfhsnxj9bneDCM0gBYGHN/EZ5Q7w2XMAiANw00Z14cbkxDdIlV4++WmV5wh
kxJk0GYA3GuWUM5QFjAKBggqhkjOPQQDAwNoADBlAjEAvjwUDBEEtNycrGfCABBH
iPIV2P/daC7rcHQjUGtGtYK8jfQ3kWwv4ZscgrH41zobAjBa2NbUqEgbPeRqvvGB
n1V5t7CFAoK4hZf4AMBtQtog6WK50Sln31WVAo36XYLKIR8=
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

cat > /var/lib/marznode/certs/key.pem << 'EOF'
cat > /var/lib/marznode/certs/key.pem << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIK8e62rZM8x3HTZNWHtfx3wLE3n9JL3DcIaedtZdXqAAoAoGCCqGSM49
AwEHoUQDQgAElIaYuSSrl97GkHeUQ47vc44CWWXMK44klglrHVBIbPRlV88mw25M
vHJvO+kbsA1l+cnRRMm2S0uKnjDxs88G8g==
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

echo "[+] Starting MarzNode Docker container..."
docker compose -f ./compose.yml up -d
cd

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
docker restart marznode-marznode-1

echo "[+] Fetching Xray keys and installing version $XRAY_VERSION..."
docker exec marznode-marznode-1 xray x25519
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
  print "      XRAY_EXECUTABLE_PATH: \"/var/lib/marznode/xray\"";
  print "      XRAY_ASSETS_PATH: \"/var/lib/marznode/data\"";
  next
}
{ print }
' "$COMPOSE_FILE" > "${COMPOSE_FILE}.tmp" && mv "${COMPOSE_FILE}.tmp" "$COMPOSE_FILE"

cd "$HOME/marznode"
docker compose down
docker compose up -d
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
echo ""
echo "🔑 X25519 Public/Private Key Pair:"
docker exec marznode-marznode-1 xray x25519
echo ""
echo "🔒 Random Hex (for UUID or other use):"
openssl rand -hex 8
echo "----------------------------------------"

echo "[+] Generating Reality keys..."
KEYS=$(docker exec marznode-marznode-1 xray x25519)
PRIVATE_KEY=$(echo "$KEYS" | grep 'Private key:' | awk '{print $3}')
PUBLIC_KEY=$(echo "$KEYS" | grep 'Public key:' | awk '{print $3}')
SHORT_ID=$(openssl rand -hex 8)

echo "[+] Writing Xray config with injected keys..."

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
