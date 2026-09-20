#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
PROBE="$RUNTIME_DIR/probe/composable_vector_graphics_value_probe.cj"
SOURCE="$RUNTIME_DIR/src/composable_vector_graphics.cj"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_VECTOR_VALUE_TMPDIR:-/private/tmp/cjgui-composable-vector-values}"

if [[ ! -f "$SOURCE" ]]; then
  print -u2 -- "CJGUI_VECTOR_VALUE_RED source_missing=1 expected_public_value_api=1"
  exit 14
fi

if rg -n "cjgui_internal_renderer|runtime_state|renderer_state|CPointer|NSEvent|NSView|Metal|AppKit" "$SOURCE" "$PROBE" >/dev/null 2>&1; then
  print -u2 -- "vector value verifier: platform/runtime leakage"
  exit 15
fi

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR"

cjc --sysroot "$SDKROOT_PATH" "$SOURCE" "$PROBE" -o "$OUTPUT_DIR/vector_value_probe" \
  >"$OUTPUT_DIR/compile.log" 2>&1
"$OUTPUT_DIR/vector_value_probe" >"$OUTPUT_DIR/result" 2>&1
cat "$OUTPUT_DIR/result"
print -- "CJGUI_VECTOR_VALUE_VERIFY source=1 probe=1 platform_free=1"
