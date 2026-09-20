#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_DATA_TRANSFER_NATIVE_TMPDIR:-/private/tmp/cjgui-data-transfer-native}"

if [[ ! -d "$SDKROOT_PATH" ]]; then
  echo "cjgui data-transfer native probe: unavailable SDKROOT=$SDKROOT_PATH" >&2
  exit 2
fi

mkdir -p "$OUTPUT_DIR"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  "$RUNTIME_DIR/native/tests/composable_data_transfer_native_probe.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc \
  -o "$OUTPUT_DIR/composable_data_transfer_native_probe"

"$OUTPUT_DIR/composable_data_transfer_native_probe"
