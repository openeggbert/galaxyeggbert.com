#!/usr/bin/env bash
# Copies the game's WebAssembly build into play/game/ so the site serves it at /play/.
#
# Usage: tools/update-web-build.sh [path/to/build-cna-webgl2]
#   default: ../galaxy-eggbert/build-cna-webgl2 (a sibling checkout of the game)
#
# The build itself is made in the game repository (see its README, "Web / Emscripten build").
# This script only copies the finished files; it never builds anything.
set -euo pipefail

site="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
build="${1:-$site/../galaxy-eggbert/build-cna-webgl2}"
build="$(cd "$build" && pwd)"
dest="$site/play/game"

for f in GalaxyEggbert.html GalaxyEggbert.js GalaxyEggbert.wasm GalaxyEggbert.data; do
    [[ -f "$build/$f" ]] || { echo "missing $build/$f, build the web target first" >&2; exit 1; }
done

mkdir -p "$dest/Content"
cp -p "$build"/GalaxyEggbert.{html,js,wasm,data} "$dest/"
# Music is streamed from Content/music at run time rather than packed into the .data file.
if [[ -d "$build/Content/music" ]]; then
    rm -rf "$dest/Content/music"
    cp -rp "$build/Content/music" "$dest/Content/music"
fi

# GitHub Pages refuses files of 100 MB or more.
big=$(find "$dest" -type f -size +99M -print)
if [[ -n "$big" ]]; then
    echo "warning: files over 99 MB will be rejected by GitHub Pages:" >&2
    echo "$big" >&2
fi

echo "Copied the web build from $build"
du -sh "$dest"
( cd "$dest" && ls -la GalaxyEggbert.* )
