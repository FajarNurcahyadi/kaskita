#!/usr/bin/env bash
# Jalankan dari folder flutter_app:  bash download_assets.sh
# URL Figma ini sementara (kedaluwarsa ~7 hari sejak dibuat). Kalau gagal,
# minta ulang lewat Figma MCP atau export manual dari Figma (PNG @2x/@3x).
set -e
mkdir -p assets/images
cd assets/images
dl() { echo "-> $2"; curl -fL --retry 2 -o "$2" "$1"; }

B1=https://www.figma.com/api/mcp/asset/453d1bee-9b72-4d97-aec6-cc7dbd8e9ea0
B2=https://www.figma.com/api/mcp/asset/dcf16690-4430-4118-a273-498e5a538766
B3=https://www.figma.com/api/mcp/asset/a4fa6afa-d291-456f-bb7f-663cadc44845
B4=https://www.figma.com/api/mcp/asset/aeda88dd-2f83-4622-9742-42ff75e3e838
B5=https://www.figma.com/api/mcp/asset/7e535551-132b-4786-91d5-db53d53bf55a
B6=https://www.figma.com/api/mcp/asset/c6041866-6e94-4e04-8014-26959f1d53af
B7=https://www.figma.com/api/mcp/asset/9c534fbe-b387-4cec-a4bd-cd6af2e8ed6c

dl $B1/f8e99.png logo_kaskita.png
dl $B2/34aba.png  cat_login.png
dl $B2/373bd.png  google.png
dl $B2/ae9cd.png  apple.png
dl $B2/099a8.png  facebook.png
dl $B3/12d03.png  phoenix.png
dl $B4/371f0.png  forgot.png
dl $B5/90fb4.png  inbox.png
dl $B6/eb363.png  card_postal.png
dl $B7/48ca6.png  join_success.png
echo "Selesai. 10 aset tersimpan di assets/images/"
