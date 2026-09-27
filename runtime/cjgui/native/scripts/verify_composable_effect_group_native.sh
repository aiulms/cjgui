#!/usr/bin/env bash
set -euo pipefail

# Build the focused P4 native probe against the real internal renderer. The
# default runs it and opens the renderer's normal test window; pass
# --compile-only for a syntax/link check without starting an app window.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_EFFECT_GROUP_TMPDIR:-/private/tmp/cjgui-effect-group}"
mkdir -p "$TMP_DIR"

SDKROOT="$(xcrun --show-sdk-path 2>/dev/null || true)"
if [ -z "$SDKROOT" ] || [ ! -d "$SDKROOT" ]; then
  SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
fi
if [ ! -d "$SDKROOT" ]; then
  echo "effect group verify: no macOS SDK available" >&2
  exit 1
fi

BIN="$TMP_DIR/composable_effect_group_probe"
LOG="$TMP_DIR/composable_effect_group_probe.log"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" \
  "$RUNTIME_DIR/probe/composable_effect_group_probe.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -o "$BIN"

if [ "${1:-}" = "--compile-only" ]; then
  echo "verify_composable_effect_group_native.sh: compile ok (not run)"
  exit 0
fi

"$BIN" 2>&1 | tee "$LOG"
if ! grep -q "effect group probe: passed isolation=true" "$LOG"; then
  echo "effect group verify: missing success marker" >&2
  exit 1
fi
echo "verify_composable_effect_group_native.sh: ok"
