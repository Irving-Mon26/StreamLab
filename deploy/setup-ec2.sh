#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"
echo '1/6 Instalando herramientas del sistema'
sudo apt-get update -qq
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg git curl ca-certificates libcap2-bin
if ! command -v node >/dev/null || ! node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>22 || a===22 && b>=13 ? 0 : 1)'; then
  curl -fsSL https://deb.nodesource.com/setup_22.x -o /tmp/streamlab-node-setup.sh
  sudo -E bash /tmp/streamlab-node-setup.sh
  sudo apt-get install -y nodejs
fi
echo '2/6 Preparando memoria swap'
if ! sudo swapon --show=NAME --noheadings | grep -qx /swapfile; then
  if [ ! -f /swapfile ]; then
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
  fi
  sudo swapon /swapfile
fi
grep -q '^/swapfile ' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
echo '3/6 Instalando dependencias'
npm ci --omit=dev --no-audit --no-fund
echo '4/6 Preparando configuración'
if [ ! -f .env ]; then
  cat > .env <<ENV
PORT=80
RTMP_PORT=1935
PUBLIC_HOST=
FFMPEG_PATH=/usr/bin/ffmpeg
RECORD_VOD=true
HLS_TIME=2
ENV
fi
sudo setcap 'cap_net_bind_service=+ep' "$(readlink -f "$(command -v node)")"
echo '5/6 Arrancando aplicación'
command -v pm2 >/dev/null || sudo npm install -g pm2 --no-audit --no-fund
if pm2 describe streamlab >/dev/null 2>&1; then
  pm2 restart streamlab --update-env
else
  pm2 start server.js --name streamlab --time
fi
pm2 save
sudo env PATH="$PATH" "$(command -v pm2)" startup systemd -u "$USER" --hp "$HOME"
echo '6/6 Comprobando respuesta'
for attempt in {1..15}; do
  if curl -fs http://127.0.0.1/api/health; then
    echo
    echo 'StreamLab listo. Abre http://IP_PUBLICA y usa Mi canal para configurar OBS.'
    exit 0
  fi
  sleep 1
done
pm2 logs streamlab --nostream --lines 30
exit 1
