#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:99

PINCHTAB_ENABLE_VNC="${PINCHTAB_ENABLE_VNC:-0}"
VNC_PASSWORD="${VNC_PASSWORD:-}"

if [ "$PINCHTAB_ENABLE_VNC" = "1" ]; then
  Xvfb :99 -screen 0 1440x900x24 >/tmp/xvfb.log 2>&1 &
  fluxbox >/tmp/fluxbox.log 2>&1 &

  if [ -n "$VNC_PASSWORD" ]; then
    mkdir -p /root/.vnc
    x11vnc -storepasswd "$VNC_PASSWORD" /root/.vnc/passwd >/dev/null 2>&1
    x11vnc -display :99 -forever -shared -rfbport 5900 -rfbauth /root/.vnc/passwd >/tmp/x11vnc.log 2>&1 &
  else
    x11vnc -display :99 -forever -shared -rfbport 5900 -nopw >/tmp/x11vnc.log 2>&1 &
  fi

  websockify --web=/usr/share/novnc/ 6080 localhost:5900 >/tmp/novnc.log 2>&1 &
fi

exec /usr/local/bin/pinchtab server
