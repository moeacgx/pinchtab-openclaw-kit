#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd)/skill/pinchtab"
DST_DIR="/root/.openclaw/skills/pinchtab"

mkdir -p "$DST_DIR"
cp "$SRC_DIR/SKILL.md" "$DST_DIR/SKILL.md"

echo "Installed pinchtab skill to: $DST_DIR"
echo "Next step: add 'pinchtab' to the target agent's skills list in OpenClaw config."
