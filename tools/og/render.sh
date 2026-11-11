#!/usr/bin/env bash
# Renders tools/og/og.html into assets/img/og-image.jpg with headless Chrome.
# Needs the site served over HTTP (fonts): python3 -m http.server 8765 in the site root.
set -euo pipefail
site="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
port="${PORT:-8765}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
profile="$work/profile"
google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --user-data-dir="$profile" \
    --window-size=1200,630 --virtual-time-budget=3000 --screenshot="$work/og.png" \
    "http://127.0.0.1:$port/tools/og/og.html" 2>/dev/null
convert "$work/og.png" -strip -quality 86 "$site/assets/img/og-image.jpg"
echo "wrote assets/img/og-image.jpg ($(du -h "$site/assets/img/og-image.jpg" | cut -f1))"
