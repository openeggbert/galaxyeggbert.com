#!/usr/bin/env bash
# Plays missions with the game's QA autoplay at Ultra graphics and grabs the window every
# 5 seconds, one mission after another (never in parallel: llvmpipe under Xvfb is CPU-heavy).
#
# Usage: tools/capture/missions.sh <out-dir> <mission>...     e.g. ... out 011 023 033
# SHOTS=N frames per mission (default 70, about six minutes).
# Each mission NNN plays $GAME_REPO/tools/autoplay/worldNNN.txt; frames land in <out-dir>/mNNN/.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
site="$(cd "$here/../.." && pwd)"
repo="${GAME_REPO:-$site/../galaxy-eggbert}"; repo="$(cd "$repo" && pwd)"
run="${SHOT_RUN:-$repo/build-probe/website-run}"
out="$(mkdir -p "$1" && cd "$1" && pwd)"; shift
mkdir -p "$run"
for m in "$@"; do
    n=$((10#$m))
    steps="$out/steps-$m.txt"
    { echo "sleep 20"; for i in $(seq -w 1 "${SHOTS:-70}"); do echo "sleep 5"; echo "shot m$m-$i"; done; } > "$steps"
    # a clean player: Ultra graphics with the terrain reliefs, windowed, no resume file
    printf 'fullscreen=0\neffectsLevel=4\nterrainRelief=1\n' > "$run/savedata.txt"
    rm -rf "$run/resume.txt" "$run/autoplay_shots" "$run/demos"
    start=$(date +%s)
    LP_NUM_THREADS="${LP_NUM_THREADS:-6}" "$here/shoot.sh" "$out/m$m" "$steps" \
        --mission "$n" --autoplay "$repo/tools/autoplay/world$m.txt"
    echo "m$m: $(( $(date +%s) - start )) s, $(ls "$out/m$m"/*.png 2>/dev/null | wc -l) frames, $(tail -1 "$run/autoplay_trace.txt" 2>/dev/null)"
done
