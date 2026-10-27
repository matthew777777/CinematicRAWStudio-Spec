#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# One-command setup for the Cinematic RAW Studio desktop tools on macOS.
#
#   scripts/install-macos.sh                 install everything
#   scripts/install-macos.sh --no-deps       skip Homebrew packages
#   scripts/install-macos.sh --add-to-path   also add ~/.local/bin to ~/.zprofile
#   PREFIX=/usr/local/bin scripts/install-macos.sh
#
# Expects the repos side by side:
#   CinematicRAWStudio-Spec, -Encoder, -Decoder, -TUI
# Installs: craw_enc craw_dec craw2dng craw_mount craw-tui craw-mount
#           craw-unmount craw-pull  ->  $PREFIX (default ~/.local/bin)
#           CRAW Mount.app, CRAW Unmount.app -> ~/Applications
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SPEC="$(dirname "$HERE")"
ROOT="$(dirname "$SPEC")"
PREFIX="${PREFIX:-$HOME/.local/bin}"
APPS="$HOME/Applications"
deps=1; add_path=0
for a in "$@"; do
    case "$a" in
        --no-deps) deps=0 ;;
        --add-to-path) add_path=1 ;;
        -h|--help) sed -n '3,17p' "$0"; exit 0 ;;
        *) echo "unknown option $a" >&2; exit 2 ;;
    esac
done
step() { printf '\n\033[1m== %s\033[0m\n' "$*"; }
fail() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

step "Checking prerequisites"
[[ "$(uname)" == Darwin ]] || fail "this installer is for macOS (see README for Linux)"
xcode-select -p > /dev/null 2>&1 || fail "install the Command Line Tools first: xcode-select --install"
for r in Encoder Decoder TUI; do
    [[ -d "$ROOT/CinematicRAWStudio-$r" ]] || fail "missing $ROOT/CinematicRAWStudio-$r (clone it next to the Spec repo)"
done
if [[ $deps == 1 ]]; then
    command -v brew > /dev/null || fail "Homebrew is required (https://brew.sh) or run with --no-deps"
    for pkg in cmake ninja ffmpeg; do
        brew list --versions "$pkg" > /dev/null 2>&1 || { echo "installing $pkg"; brew install "$pkg"; }
    done
    if [[ ! -e /usr/local/lib/libfuse-t.dylib ]]; then
        echo "installing fuse-t (kext-free FUSE, needed by craw-mount)"
        brew install --cask macos-fuse-t/cask/fuse-t
    fi
fi
for t in cmake ninja; do command -v $t > /dev/null || fail "$t not found"; done
command -v ffmpeg > /dev/null || echo "note: ffmpeg not found; craw-tui will only export CinemaDNG"

build() {  # build REPO TARGETS...
    local repo="$ROOT/CinematicRAWStudio-$1"; shift
    step "Building $(basename "$repo")"
    cmake -S "$repo" -B "$repo/build-release" -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null
    ninja -C "$repo/build-release" "$@" | tail -1
}
build Encoder craw_enc craw_enc_conformance
build Decoder craw_dec craw_dec_conformance craw2dng craw_mount
build TUI craw-tui develop_tests

step "Self-tests"
"$ROOT/CinematicRAWStudio-Encoder/build-release/craw_enc_conformance" | tail -1
"$ROOT/CinematicRAWStudio-Decoder/build-release/craw_dec_conformance" | tail -1
"$ROOT/CinematicRAWStudio-TUI/build-release/develop_tests" | tail -1

step "Installing tools to $PREFIX"
mkdir -p "$PREFIX"
install -m 755 "$ROOT/CinematicRAWStudio-Encoder/build-release/craw_enc" "$PREFIX/"
for b in craw_dec craw2dng craw_mount; do
    [[ -x "$ROOT/CinematicRAWStudio-Decoder/build-release/$b" ]] && install -m 755 "$ROOT/CinematicRAWStudio-Decoder/build-release/$b" "$PREFIX/"
done
install -m 755 "$ROOT/CinematicRAWStudio-TUI/build-release/craw-tui" "$PREFIX/"
for s in craw-mount craw-unmount craw-pull; do install -m 755 "$HERE/macos/$s" "$PREFIX/"; done
ls -1 "$PREFIX" | grep -E '^craw' | sed 's/^/  /'

step "Creating CRAW Mount.app and CRAW Unmount.app in $APPS"
mkdir -p "$APPS"
rm -rf "$APPS/CRAW Mount.app" "$APPS/CRAW Unmount.app"
osacompile -o "$APPS/CRAW Mount.app" "$HERE/macos/CRAWMount.applescript"
osacompile -o "$APPS/CRAW Unmount.app" "$HERE/macos/CRAWUnmount.applescript"
# Let Finder offer "Open With > CRAW Mount" for .craw files.
plist="$APPS/CRAW Mount.app/Contents/Info.plist"
plutil -replace CFBundleIdentifier -string org.cinematicrawstudio.crawmount "$plist"
plutil -replace CFBundleDocumentTypes -json '[{"CFBundleTypeName":"Cinematic RAW Studio take","CFBundleTypeRole":"Viewer","CFBundleTypeExtensions":["craw","CRAW"],"LSHandlerRank":"Owner"}]' "$plist"
codesign --force --sign - "$APPS/CRAW Mount.app" > /dev/null 2>&1 || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APPS/CRAW Mount.app"
echo "  $APPS/CRAW Mount.app"
echo "  $APPS/CRAW Unmount.app"

if [[ ":$PATH:" != *":$PREFIX:"* ]]; then
    if [[ $add_path == 1 ]]; then
        echo "export PATH=\"$PREFIX:\$PATH\"" >> "$HOME/.zprofile"
        echo "added $PREFIX to PATH in ~/.zprofile (open a new terminal)"
    else
        printf '\nnote: %s is not on PATH. Add it with:\n  echo '\''export PATH="%s:$PATH"'\'' >> ~/.zprofile\n' "$PREFIX" "$PREFIX"
    fi
fi

step "Done"
cat <<MSG
Mount a take for DaVinci Resolve:
  • double-click a .craw → Open With → CRAW Mount (or drop it on CRAW Mount.app), or
  • craw-mount --open ~/Movies/CRAW/IMG_..._VID.craw
Pull the newest take from the phone and mount it:  craw-pull --mount
Unmount everything:  craw-unmount   (or CRAW Unmount.app)
Render/grade in the terminal:  craw-tui ~/Movies/CRAW
MSG
