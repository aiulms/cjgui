#!/usr/bin/env zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT_DIR/scripts/env.sh"

BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

clang \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$ROOT_DIR/native/c_math_smoke.c" \
  -o "$BUILD_DIR/c_math_smoke.o"
ar rcs "$BUILD_DIR/libc_math_smoke.a" "$BUILD_DIR/c_math_smoke.o"

cjc "$ROOT_DIR/src/main.cj" \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$BUILD_DIR" \
  -lc_math_smoke \
  -o "$BUILD_DIR/cffi_smoke"

"$BUILD_DIR/cffi_smoke"
