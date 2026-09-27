#!/usr/bin/env zsh

# Focused native proof for the P1 shape-effect draw gate, painter order and
# hit-test boundary. It compiles only the internal renderer sidecar plus this
# probe (never the Cangjie package, so it cannot race other writers) and then
# asserts the probe's success marker, failing the script on any non-zero exit.
#
# Covered contracts:
#   - an empty own clip still lets an outer shadow reach the viewport;
#   - the shadow obeys every ancestor clip constraint with intersection
#     semantics, and disappears when its output range leaves the viewport;
#   - the body fill paints after the shadow (painter order);
#   - hit testing stays bounds-only and never widens to the shadow;
#   - a no-effect node still paints through the ordinary shape path;
#   - encoder stats show the real extra vertices an effect costs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_EFFECT_GATE_TMPDIR:-/private/tmp/cjgui-effect-gate}"
mkdir -p "$TMP_DIR"

# Prefer the active toolchain SDK, then fall back to the CommandLineTools SDK
# used by the existing composable scene verifier.
SDKROOT="$(xcrun --show-sdk-path 2>/dev/null || true)"
if [ -z "$SDKROOT" ] || [ ! -d "$SDKROOT" ]; then
  SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
fi
if [ ! -d "$SDKROOT" ]; then
  echo "effect gate verify: no macOS SDK available" >&2
  exit 1
fi

BIN="$TMP_DIR/composable_effect_gate_probe"
LOG="$TMP_DIR/composable_effect_gate_probe.log"

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING \
  -isysroot "$SDKROOT" -mmacosx-version-min=12.0 \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" "$RUNTIME_DIR/probe/composable_effect_gate_probe.m" \
  -framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -o "$BIN"

"$BIN" | tee "$LOG"

if ! grep -q "effect gate probe: passed" "$LOG"; then
  echo "effect gate verify: missing success marker" >&2
  exit 1
fi

echo "verify_effect_gate.sh: ok"