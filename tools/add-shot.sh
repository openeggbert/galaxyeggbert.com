#!/usr/bin/env bash
# Turns a raw game capture into the site's two WebP sizes.
#
# Usage: tools/add-shot.sh <capture.png> <name> [crop]
#   writes assets/shots/<name>.webp        (full size, 1600x960, for the lightbox)
#          assets/shots/thumb/<name>.webp  (800x480, for the page)
#   crop:  optional ImageMagick geometry applied first, e.g. 1600x960+0+0
#
# Captures come from tools/capture/ (the game under Xvfb at 1600x960, Ultra graphics).
set -euo pipefail
site="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$1"; name="$2"; crop="${3:-}"
mkdir -p "$site/assets/shots/thumb"
args=()
[[ -n "$crop" ]] && args+=(-crop "$crop" +repage)
convert "$src" "${args[@]}" -resize '1600x960^' -gravity center -extent 1600x960 -strip \
    -quality 82 -define webp:method=6 "$site/assets/shots/$name.webp"
convert "$src" "${args[@]}" -resize '800x480^' -gravity center -extent 800x480 -strip \
    -unsharp 0x0.6+0.6+0 -quality 80 -define webp:method=6 "$site/assets/shots/thumb/$name.webp"
printf '%s  %s  %s\n' "$name" "$(du -h "$site/assets/shots/$name.webp" | cut -f1)" "$(du -h "$site/assets/shots/thumb/$name.webp" | cut -f1)"
