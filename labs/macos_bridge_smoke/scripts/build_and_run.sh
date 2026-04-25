#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/env.sh"

BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

echo "cjgui: using SDKROOT=$CJ_GUI_SDKROOT"

clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$ROOT_DIR/native/cjgui_macos.m" \
  -o "$BUILD_DIR/cjgui_macos.o"

ar rcs "$BUILD_DIR/libcjgui_macos.a" "$BUILD_DIR/cjgui_macos.o"

cjc "$ROOT_DIR/src/main.cj" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$BUILD_DIR" \
  -lcjgui_macos \
  --link-option "-framework" \
  --link-option "AppKit" \
  --link-option "-framework" \
  --link-option "Metal" \
  --link-option "-framework" \
  --link-option "QuartzCore" \
  --link-option "-lobjc" \
  -o "$BUILD_DIR/macos_bridge_smoke"

"$BUILD_DIR/macos_bridge_smoke"
