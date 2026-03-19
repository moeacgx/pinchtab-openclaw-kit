#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")/.." && pwd)/docker/pinchtab-debian"
cd "$BASE_DIR"

ENABLE_VNC="${ENABLE_VNC:-1}"
VNC_PASSWORD="${VNC_PASSWORD:-changeme}"

if [ ! -f pinchtab.container.json ]; then
  cp pinchtab.container.json.example pinchtab.container.json
  echo "Created pinchtab.container.json from example. Please edit server.token first."
  exit 0
fi

docker build -t pinchtab-debian:latest .

docker rm -f pinchtab-debian >/dev/null 2>&1 || true

ARGS=(
  -d --name pinchtab-debian
  -p 127.0.0.1:9867:9867
  -v /var/lib/pinchtab:/var/lib/pinchtab
  -v /var/lib/pinchtab/profiles:/var/lib/pinchtab/profiles
  -v "$BASE_DIR/pinchtab.container.json":/etc/pinchtab.json:ro
  -e PINCHTAB_CONFIG=/etc/pinchtab.json
)

if [ "$ENABLE_VNC" = "1" ]; then
  ARGS+=(
    -p 127.0.0.1:5900:5900
    -p 127.0.0.1:6080:6080
    -e PINCHTAB_ENABLE_VNC=1
    -e VNC_PASSWORD="$VNC_PASSWORD"
  )
else
  ARGS+=(
    -e PINCHTAB_ENABLE_VNC=0
  )
fi

docker run "${ARGS[@]}" pinchtab-debian:latest

echo "PinchTab Debian container started on 127.0.0.1:9867"
if [ "$ENABLE_VNC" = "1" ]; then
  echo "Default VNC mode enabled on 127.0.0.1:5900"
  echo "Default noVNC web entry: http://127.0.0.1:6080/vnc.html"
else
  echo "VNC disabled explicitly; only API mode is enabled"
fi
