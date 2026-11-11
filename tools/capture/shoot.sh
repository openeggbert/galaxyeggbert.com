#!/usr/bin/env bash
# Runs the native game under its own Xvfb display and grabs the window at the moments a steps
# file asks for. Adapted from the game repository's tools/qa_live.sh.
#
# Usage: tools/capture/shoot.sh <out-dir> <steps-file> [game arguments...]
#   e.g. tools/capture/shoot.sh out/m105 steps.txt --mission 105 --autoplay "$GAME/tools/autoplay/world105.txt"
#
# Environment:
#   GAME_REPO   the game checkout (default: ../galaxy-eggbert next to this site)
#   GAME_BUILD  its native build directory (default: $GAME_REPO/build-cna-opengl3)
#   SHOT_W/H    window and display size (default 1600x960, the game's 5:3)
#   SHOT_RUN    run directory with the player's files (default: $GAME_REPO/build-probe/website-run)
#   CLICK_HOLD  seconds a click holds the button (default 0.8: slow Ultra frames miss short clicks)
#   GAME_BINARY a specific GalaxyEggbert executable to run (default: $GAME_BUILD/GalaxyEggbert)
#
# Steps, one per line:  sleep <s> | shot <name> | key <keysyms> | keydown/keyup <keysym>
#                       click <x> <y> | move <x> <y> | type <word> | focus | geom
# The run stops early when the game exits (an autoplay script that ends closes it).
set -u
site="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
repo="${GAME_REPO:-$site/../galaxy-eggbert}"; repo="$(cd "$repo" && pwd)"
build="${GAME_BUILD:-$repo/build-cna-opengl3}"
out="$(mkdir -p "$1" && cd "$1" && pwd)"
steps="$(cd "$(dirname "$2")" && pwd)/$(basename "$2")"
shift 2
W=${SHOT_W:-1600}; H=${SHOT_H:-960}
if [[ -z "${SHOOT_INNER:-}" ]]; then
    SHOOT_INNER=1 exec xvfb-run -a -s "-screen 0 ${W}x${H}x24" "$0" "$out" "$steps" "$@"
fi
run="${SHOT_RUN:-$repo/build-probe/website-run}"
mkdir -p "$run"
for d in Content avatars3d textures3d worlds3d; do ln -sfn "$repo/$d" "$run/$d"; done
# A hard link (or copy), not a symlink: CNA finds its content next to the executable's real path.
# GAME_BINARY pins one binary for a whole series of runs while the build directory keeps changing.
bin="${GAME_BINARY:-$build/GalaxyEggbert}"
rm -f "$run/GalaxyEggbert"; ln "$bin" "$run/GalaxyEggbert" 2>/dev/null || cp -p "$bin" "$run/GalaxyEggbert"
export GALAXY_USER_DIR="$run"
cd "$run"
SDL_AUDIODRIVER=dummy SDL_VIDEODRIVER=x11 ./GalaxyEggbert "$@" > "$out/game.log" 2>&1 &
pid=$!
wid=""
for _ in $(seq 200); do wid=$(xdotool search --onlyvisible --pid "$pid" 2>/dev/null | tail -1); [[ -n "$wid" ]] && break; sleep 0.1; done
fit() { xdotool windowmove "$wid" 0 0 2>/dev/null; xdotool windowsize "$wid" "$W" "$H" 2>/dev/null; }
fitted() { local g; g=$(xdotool getwindowgeometry "$wid" 2>/dev/null | awk '/Geometry/{print $2}'); [[ "$g" == "${W}x${H}" ]]; }
sleep 0.5; fit; sleep 1; fit
xdotool windowfocus "$wid" 2>/dev/null
while read -r cmd a b; do
    kill -0 "$pid" 2>/dev/null || break
    case "$cmd" in
        sleep) for _ in $(seq "$a"); do kill -0 "$pid" 2>/dev/null || break; sleep 1; done ;;
        shot)  if ! fitted; then fit; sleep 2; fi
               import -window root +repage "$out/$a.png" ;;
        key) xdotool key --delay 80 $a ;;
        keydown) xdotool keydown "$a" ;;
        keyup) xdotool keyup "$a" ;;
        click) xdotool mousemove "$a" "$b"; sleep 0.4; xdotool mousedown 1; sleep "${CLICK_HOLD:-0.8}"; xdotool mouseup 1 ;;
        move) xdotool mousemove "$a" "$b" ;;
        focus) xdotool windowfocus "$wid" 2>/dev/null ;;
        type) xdotool type --delay 150 "$a" ;;
        geom) xdotool getwindowgeometry "$wid" >> "$out/geom.txt" ;;
        "#"*|"") ;;
        *) echo "shoot.sh: unknown step '$cmd'" >&2 ;;
    esac
done < "$steps"
kill "$pid" 2>/dev/null; sleep 1; kill -9 "$pid" 2>/dev/null
exit 0
