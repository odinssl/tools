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
MIIDljCCAx2gAwIBAgISBq6u68J75DiYrc8K6Tju6r4CMAoGCCqGSM49BAMDMDIx
CzAJBgNVBAYTAlVTMRYwFAYDVQQKEw1MZXQncyBFbmNyeXB0MQswCQYDVQQDEwJF
NTAeFw0yNTA3MjkxODIxNTFaFw0yNTEwMjcxODIxNTBaMBgxFjAUBgNVBAMTDWJy
aW1saXNraS5jb20wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAAQRBQZ6X4ymehXv
7FjXTKnCsIL6Df0/DFz7PRPLpxeLCi1M1Pab45QY3zr4oLTvdEnMmvisu7gI3ggC
py9nYjA4o4ICKzCCAicwDgYDVR0PAQH/BAQDAgeAMB0GA1UdJQQWMBQGCCsGAQUF
BwMBBggrBgEFBQcDAjAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBRXMmbEurPyAXDy
wGCRaV5UF2zZnTAfBgNVHSMEGDAWgBSfK1/PPCFPnQS37SssxMZwi9LXDTAyBggr
BgEFBQcBAQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly9lNS5pLmxlbmNyLm9yZy8w
KQYDVR0RBCIwIIIPKi5icmltbGlza2kuY29tgg1icmltbGlza2kuY29tMBMGA1Ud
IAQMMAowCAYGZ4EMAQIBMCwGA1UdHwQlMCMwIaAfoB2GG2h0dHA6Ly9lNS5jLmxl
bmNyLm9yZy8zLmNybDCCAQQGCisGAQQB1nkCBAIEgfUEgfIA8AB2AN3cyjSV1+EW
BeeVMvrHn/g9HFDf2wA6FBJ2Ciysu8gqAAABmFeg8LYAAAQDAEcwRQIhAPM7Pwst
1g8OLEw2ipybNGLtrjY6YonN3N9Go1FrB/fWAiBr9jRc9AGJL6H9mwOZy47jNCqh
5rn1xFfNse1nWCrW0gB2ABoE/0nQVB1Ar/agw7/x2MRnL07s7iNAaJhrF0Au3Il9
AAABmFeg+GkAAAQDAEcwRQIgaCCQ4hPGj+wtJJUsf8PsSgOclPNHiJcx1ygG9x1j
OdkCIQCikMFFAJs5knaKqpBJ9wKHPSOdGpkBuph0VjN5VgLdRjAKBggqhkjOPQQD
AwNnADBkAjAI3Uib0Rts06PvaKKZG0k7ZcWMGR7jH1cIXALOf7fG7DNVUJaN0WDE
+/lRHvvmvrECMFzpzNrTlK71N6uMKuPhQi7yzPD6l5jv0FdoD36c9ym3u0RS4gr7
21j0lKXkAW5P7w==
-----END CERTIFICATE-----

-----BEGIN CERTIFICATE-----
MIIEVzCCAj+gAwIBAgIRAIOPbGPOsTmMYgZigxXJ/d4wDQYJKoZIhvcNAQELBQAw
TzELMAkGA1UEBhMCVVMxKTAnBgNVBAoTIEludGVybmV0IFNlY3VyaXR5IFJlc2Vh
cmNoIEdyb3VwMRUwEwYDVQQDEwxJU1JHIFJvb3QgWDEwHhcNMjQwMzEzMDAwMDAw
WhcNMjcwMzEyMjM1OTU5WjAyMQswCQYDVQQGEwJVUzEWMBQGA1UEChMNTGV0J3Mg
RW5jcnlwdDELMAkGA1UEAxMCRTUwdjAQBgcqhkjOPQIBBgUrgQQAIgNiAAQNCzqK
a2GOtu/cX1jnxkJFVKtj9mZhSAouWXW0gQI3ULc/FnncmOyhKJdyIBwsz9V8UiBO
VHhbhBRrwJCuhezAUUE8Wod/Bk3U/mDR+mwt4X2VEIiiCFQPmRpM5uoKrNijgfgw
gfUwDgYDVR0PAQH/BAQDAgGGMB0GA1UdJQQWMBQGCCsGAQUFBwMCBggrBgEFBQcD
ATASBgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBSfK1/PPCFPnQS37SssxMZw
i9LXDTAfBgNVHSMEGDAWgBR5tFnme7bl5AFzgAiIyBpY9umbbjAyBggrBgEFBQcB
AQQmMCQwIgYIKwYBBQUHMAKGFmh0dHA6Ly94MS5pLmxlbmNyLm9yZy8wEwYDVR0g
BAwwCjAIBgZngQwBAgEwJwYDVR0fBCAwHjAcoBqgGIYWaHR0cDovL3gxLmMubGVu
Y3Iub3JnLzANBgkqhkiG9w0BAQsFAAOCAgEAH3KdNEVCQdqk0LKyuNImTKdRJY1C
2uw2SJajuhqkyGPY8C+zzsufZ+mgnhnq1A2KVQOSykOEnUbx1cy637rBAihx97r+
bcwbZM6sTDIaEriR/PLk6LKs9Be0uoVxgOKDcpG9svD33J+G9Lcfv1K9luDmSTgG
6XNFIN5vfI5gs/lMPyojEMdIzK9blcl2/1vKxO8WGCcjvsQ1nJ/Pwt8LQZBfOFyV
XP8ubAp/au3dc4EKWG9MO5zcx1qT9+NXRGdVWxGvmBFRAajciMfXME1ZuGmk3/GO
koAM7ZkjZmleyokP1LGzmfJcUd9s7eeu1/9/eg5XlXd/55GtYjAM+C4DG5i7eaNq
cm2F+yxYIPt6cbbtYVNJCGfHWqHEQ4FYStUyFnv8sjyqU8ypgZaNJ9aVcWSICLOI
E1/Qv/7oKsnZCWJ926wU6RqG1OYPGOi1zuABhLw61cuPVDT28nQS/e6z95cJXq0e
K1BcaJ6fJZsmbjRgD5p3mvEf5vdQM7MCEvU0tHbsx2I5mHHJoABHb8KVBgWp/lcX
GWiWaeOyB7RP+OfDtvi2OsapxXiV7vNVs7fMlrRjY1joKaqmmycnBvAq14AEbtyL
sVfOS66B8apkeFX2NY4XPEYV4ZSCe8VHPrdrERk2wILG3T/EGmSIkCYVUMSnjmJd
VQD9F6Na/+zmXCc=
-----END CERTIFICATE-----
EOF

cat > /var/lib/marznode/certs/key.pem << 'EOF'
cat > /var/lib/marznode/certs/key.pem << 'EOF'
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEINJyjmrqcbiZ5evujJT6/61AqOZbiADdxdIdmhhPWojroAoGCCqGSM49
AwEHoUQDQgAEEQUGel+MpnoV7+xY10ypwrCC+g39Pwxc+z0Ty6cXiwotTNT2m+OU
GN86+KC073RJzJr4rLu4CN4IAqcvZ2IwOA==
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

echo "[+] Fixing DNS resolver..."
chattr -i /etc/resolv.conf || true
rm -f /etc/resolv.conf
echo -e 'nameserver 1.1.1.1\nnameserver 1.0.0.1' > /etc/resolv.conf
chattr +i /etc/resolv.conf || true

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
