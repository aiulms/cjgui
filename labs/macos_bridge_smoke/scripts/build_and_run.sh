#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/env.sh"

# Runtime-owned renderer lives in the cjgui runtime tree.
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
RUNTIME_DIR="$REPO_DIR/runtime/cjgui"

BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

echo "cjgui: using SDKROOT=$CJ_GUI_SDKROOT"

# 1. Compile the runtime-owned internal renderer archive (single source of
#    truth for the real Metal implementation).
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  -o "$BUILD_DIR/cjgui_internal_renderer.o"

ar rcs "$BUILD_DIR/libcjgui_internal_renderer.a" "$BUILD_DIR/cjgui_internal_renderer.o"

# 2. Compile the legacy smoke shim, which now calls the runtime-owned session
#    API and contains no second renderer copy.
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -I "$RUNTIME_DIR/native" \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$ROOT_DIR/native/cjgui_macos.m" \
  -o "$BUILD_DIR/cjgui_macos.o"

ar rcs "$BUILD_DIR/libcjgui_macos.a" "$BUILD_DIR/cjgui_macos.o"

# 3. Compile the Cangjie entry, link both archives + frameworks.
cjc "$ROOT_DIR/src/main.cj" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$BUILD_DIR" \
  -lcjgui_internal_renderer \
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
