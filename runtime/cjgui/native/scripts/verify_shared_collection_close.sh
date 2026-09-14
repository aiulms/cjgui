#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${TMPDIR:-/tmp}/cjgui-shared-collection-close-probe"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui collection close probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi
mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  "$RUNTIME_DIR/probe/shared_collection_close_probe.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/shared_collection_close_probe"
"$OUTPUT_DIR/shared_collection_close_probe"
