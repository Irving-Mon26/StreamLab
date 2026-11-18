#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
node -e 'const [a,b]=process.versions.node.split(".").map(Number); if(a<22 || a===22 && b<13) { console.error("Instala Node 22.13 o superior"); process.exit(1); }'
FFMPEG_BIN=$(command -v ffmpeg || true)
if [ -z "$FFMPEG_BIN" ]; then echo 'Falta ffmpeg. En PowerShell: winget install Gyan.FFmpeg. Después vuelve a abrir Git Bash.'; exit 1; fi
if command -v cygpath >/dev/null; then FFMPEG_BIN=$(cygpath -m "$FFMPEG_BIN"); fi
if [ ! -f .env ]; then
  cat > .env <<ENV
PORT=3000
RTMP_PORT=1935
PUBLIC_HOST=
FFMPEG_PATH=$FFMPEG_BIN
RECORD_VOD=true
HLS_TIME=2
ENV
else
  echo 'Ya existe .env: se conserva. Revisa FFMPEG_PATH si el video no aparece.'
fi
npm ci --no-audit --no-fund
echo 'Listo. Ejecuta npm start y abre http://localhost:3000'
