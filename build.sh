#!/usr/bin/env bash
# Export the Web build and publish it to itch.io.
#   ./build.sh              export (release) + push
#   ./build.sh --no-push    export only
#   ./build.sh --debug      export a debug build (profiler, verbose errors)
set -euo pipefail

GODOT="${GODOT:-$HOME/Applications/Godot_v4.7.1-stable_linux.x86_64}"
BUTLER="${BUTLER:-$HOME/Applications/butler}"
ITCH_TARGET="${ITCH_TARGET:-frogwizardhat/gmtk2026:html5}"
PRESET="Web"
OUT_DIR="build/web"

PUSH=1
EXPORT_MODE="--export-release"
for arg in "$@"; do
	case "$arg" in
		-n|--no-push) PUSH=0 ;;
		--debug) EXPORT_MODE="--export-debug" ;;
		*) echo "unknown option: $arg" >&2; exit 2 ;;
	esac
done

cd "$(dirname "$(readlink -f "$0")")"

[ -x "$GODOT" ] || { echo "godot not found at $GODOT (override with GODOT=...)" >&2; exit 1; }
if [ "$PUSH" = 1 ]; then
	[ -x "$BUTLER" ] || { echo "butler not found at $BUTLER (override with BUTLER=...)" >&2; exit 1; }
fi

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# Fresh clones / newly added assets have no .godot cache; exporting without
# importing first produces a build with missing resources.
echo "==> importing assets"
"$GODOT" --headless --path . --import

echo "==> exporting $PRESET"
"$GODOT" --headless --path . $EXPORT_MODE "$PRESET" "$OUT_DIR/index.html"

# Godot can exit 0 on a partial export, so check the artifacts ourselves.
for f in index.html index.js index.wasm index.pck; do
	[ -s "$OUT_DIR/$f" ] || { echo "export failed: $OUT_DIR/$f missing or empty" >&2; exit 1; }
done
echo "==> built $OUT_DIR ($(du -sh "$OUT_DIR" | cut -f1))"

if [ "$PUSH" = 0 ]; then
	echo "--no-push given, stopping before upload."
	exit 0
fi

if git rev-parse --git-dir >/dev/null 2>&1; then
	VERSION="$(git rev-list --count HEAD).$(git rev-parse --short HEAD)"
	[ -z "$(git status --porcelain)" ] || VERSION="$VERSION-dirty"
else
	VERSION="0.manual"
fi

echo "==> pushing $VERSION to $ITCH_TARGET"
"$BUTLER" push "$OUT_DIR" "$ITCH_TARGET" --userversion "$VERSION"

echo
"$BUTLER" status "$ITCH_TARGET"
echo
echo "https://frogwizardhat.itch.io/gmtk2026"
