#!/usr/bin/env zsh
#
# Focused R1 verifier for the runtime-owned internal renderer clear-window
# vertical slice.
#
# Scope (single focused verifier, no per-function owner/packet/suite scripts):
#   1. Build the internal native static archive (cjgui_internal_renderer.m).
#   2. Compile the Cangjie wrapper (runtime_renderer_session.cj) + probe
#      (runtime_renderer_clear_window_probe.cj) in the SAME package, so
#      internal symbols stay internal (no public visibility promotion).
#   3. Link native archive + AppKit/Metal/QuartzCore.
#   4. Run the probe.
#   5. Assert main-thread admission, session creation, two frames submitted,
#      readback completed + clear color matched, bounded pump, close + destroy,
#      occupied session count back to 0, process exit 0.
#
# Stop-line: no runtime_state / renderer_state write, no stable public C ABI,
# no modification to the existing 225-function native bridge.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$RUNTIME_DIR/../.." && pwd)"

INTERNAL_HDR="$RUNTIME_DIR/native/cjgui_internal_renderer.h"
INTERNAL_SRC="$RUNTIME_DIR/native/cjgui_internal_renderer.m"
WRAPPER_SRC="$RUNTIME_DIR/src/runtime_renderer_session.cj"
PROBE_SRC="$RUNTIME_DIR/probe/runtime_renderer_clear_window_probe.cj"
ACCESSIBILITY_PROBE_SRC="$RUNTIME_DIR/probe/shared_operation_accessibility_probe.m"
VIEWPORT_PROBE_SRC="$RUNTIME_DIR/probe/shared_operation_viewport_probe.m"

TMP_DIR="${CJGUI_INTERNAL_RENDERER_TMPDIR:-/private/tmp/cjgui-internal-renderer-clear-window}"
BUILD_DIR="$TMP_DIR/build"
PACKAGE_DIR="$TMP_DIR/package"
OUTPUT_LOG="$TMP_DIR/probe-output.log"
EXECUTABLE="$BUILD_DIR/cjgui_internal_renderer_clear_window_probe"
ACCESSIBILITY_EXECUTABLE="$BUILD_DIR/cjgui_shared_operation_accessibility_probe"
ACCESSIBILITY_OUTPUT_LOG="$TMP_DIR/shared-operation-accessibility-output.log"
VIEWPORT_EXECUTABLE="$BUILD_DIR/cjgui_shared_operation_viewport_probe"
VIEWPORT_OUTPUT_LOG="$TMP_DIR/shared-operation-viewport-output.log"

mkdir -p "$TMP_DIR" "$BUILD_DIR" "$PACKAGE_DIR"
: > "$OUTPUT_LOG"

# ---- source existence preconditions ----
for f in "$INTERNAL_HDR" "$INTERNAL_SRC" "$WRAPPER_SRC" "$PROBE_SRC" \
  "$ACCESSIBILITY_PROBE_SRC" "$VIEWPORT_PROBE_SRC"; do
  if [[ ! -f "$f" ]]; then
    echo "cjgui internal renderer verifier: missing source $f" >&2
    exit 2
  fi
done

# ---- toolchain bootstrap ----
PS_SHIM_DIR="$TMP_DIR/ps-shim"
mkdir -p "$PS_SHIM_DIR"
cat > "$PS_SHIM_DIR/ps" <<'EOF'
#!/usr/bin/env sh
echo zsh
EOF
chmod +x "$PS_SHIM_DIR/ps"

if ! command -v cjc >/dev/null 2>&1 || ! command -v clang >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    export PATH="$PS_SHIM_DIR:$PATH"
    set +u
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
    set -u
  fi
fi

if ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui internal renderer verifier: cjc not found" >&2
  exit 7
fi
if ! command -v clang >/dev/null 2>&1; then
  echo "cjgui internal renderer verifier: clang not found" >&2
  exit 7
fi

KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui internal renderer verifier: SDKROOT not found" >&2
  exit 9
fi
export SDKROOT="$CJ_GUI_SDKROOT"

echo "cjgui internal renderer verifier: SDKROOT=$CJ_GUI_SDKROOT"
echo "cjgui internal renderer verifier: building native archive"

# ---- 1. compile internal native archive ----
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$INTERNAL_SRC" \
  -o "$BUILD_DIR/cjgui_internal_renderer.o"

ar rcs "$BUILD_DIR/libcjgui_internal_renderer.a" "$BUILD_DIR/cjgui_internal_renderer.o"
echo "cjgui internal renderer verifier: native archive built"

# ---- 2. compile Cangjie wrapper + probe in one package ----
#
# Both wrapper and probe declare `package cjgui`, so internal symbols are
# accessible inside the same package without any public promotion.
# We pass the package root so cjc can resolve both files.
"$PACKAGE_DIR" >/dev/null 2>&1 || true
mkdir -p "$PACKAGE_DIR"
# Place a cjpm.toml so we could also use cjpm; but we use direct cjc here for a
# minimal focused build.
cp "$WRAPPER_SRC" "$PACKAGE_DIR/runtime_renderer_session.cj"
cp "$PROBE_SRC" "$PACKAGE_DIR/runtime_renderer_clear_window_probe.cj"

CANGJIE_RUNTIME_DYLIB="$(find "${CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie}/runtime/lib" -maxdepth 2 -name libcangjie-runtime.dylib -print -quit 2>/dev/null || true)"
CANGJIE_RUNTIME_LIB_DIR=""
if [[ -n "$CANGJIE_RUNTIME_DYLIB" ]]; then
  CANGJIE_RUNTIME_LIB_DIR="$(dirname "$CANGJIE_RUNTIME_DYLIB")"
  export DYLD_LIBRARY_PATH="${CANGJIE_RUNTIME_LIB_DIR}:${DYLD_LIBRARY_PATH:-}"
fi

echo "cjgui internal renderer verifier: compiling cangjie wrapper + probe"
cjc \
  --sysroot "$CJ_GUI_SDKROOT" \
  -L "$BUILD_DIR" \
  -lcjgui_internal_renderer \
  --link-option "-framework" \
  --link-option "AppKit" \
  --link-option "-framework" \
  --link-option "Metal" \
  --link-option "-framework" \
  --link-option "QuartzCore" \
  --link-option "-lobjc" \
  "$PACKAGE_DIR/runtime_renderer_session.cj" \
  "$PACKAGE_DIR/runtime_renderer_clear_window_probe.cj" \
  -o "$EXECUTABLE"
echo "cjgui internal renderer verifier: probe linked"

# ---- 3. run probe ----
echo "cjgui internal renderer verifier: running probe"
set +e
"$EXECUTABLE" 2>&1 | tee "$OUTPUT_LOG"
probe_status=${pipestatus[1]}
set -e

if [[ "$probe_status" -ne 0 ]]; then
  echo "cjgui internal renderer verifier: probe exit status=$probe_status" >&2
  echo "cjgui internal renderer verifier: log=$OUTPUT_LOG" >&2
  exit "$probe_status"
fi

# ---- 4. assertions ----
require_line() {
  local expected="$1"
  if ! grep -F "$expected" "$OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui internal renderer verifier: missing output line: $expected" >&2
    echo "cjgui internal renderer verifier: full output follows" >&2
    cat "$OUTPUT_LOG" >&2
    exit 10
  fi
}

require_line "cjgui: starting runtime-owned internal renderer probe"
require_line "cjgui probe: main thread admitted=true"
require_line "cjgui probe: session created"
require_line "cjgui: bridge init"
require_line "cjgui: capability check: metal device ok"
require_line "cjgui: capability check: command queue ok"
require_line "cjgui: window created"
require_line "cjgui: metal setup complete"
require_line "cjgui: first frame rendered"
require_line "cjgui probe: frame 1 submitted index=1"
require_line "cjgui probe: frame 1 readback attempted=1"
require_line "cjgui probe: frame 1 readback completed=1"
require_line "cjgui probe: frame 1 readback color matched=1"
require_line "cjgui: metal readback: requested=true"
require_line "cjgui: metal readback: command_buffer_completed=true"
require_line "cjgui: metal readback: source=clear_color_probe"
require_line "cjgui: metal readback: clear_color_match=true"
require_line "cjgui: metal readback: success=true degraded=none"
require_line "cjgui probe: frame 2 submitted index=2"
require_line "cjgui probe: bounded pump completed"
require_line "cjgui probe: close requested=true"
require_line "cjgui probe: destroyed=true"
require_line "cjgui probe: occupied session count=0"
require_line "cjgui probe: exit=0"
require_line "cjgui: destroy complete"
require_line "cjgui: close requested"

# ---- 5. native accessibility projection regression ----
#
# The renderer draws these controls itself, so this probe reaches the concrete
# NSAccessibilityElement children rather than merely checking Cangjie state.
echo "cjgui internal renderer verifier: compiling shared-operation accessibility probe"
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  "$ACCESSIBILITY_PROBE_SRC" \
  -L "$BUILD_DIR" \
  -lcjgui_internal_renderer \
  -framework AppKit \
  -framework Metal \
  -framework MetalKit \
  -framework QuartzCore \
  -o "$ACCESSIBILITY_EXECUTABLE"

echo "cjgui internal renderer verifier: running shared-operation accessibility probe"
: > "$ACCESSIBILITY_OUTPUT_LOG"
set +e
"$ACCESSIBILITY_EXECUTABLE" 2>&1 | tee "$ACCESSIBILITY_OUTPUT_LOG"
accessibility_status=${pipestatus[1]}
set -e
if [[ "$accessibility_status" -ne 0 ]]; then
  echo "cjgui internal renderer verifier: accessibility probe exit status=$accessibility_status" >&2
  exit "$accessibility_status"
fi
if [[ "$(grep -Fc 'cjgui accessibility probe: enabled=true' "$ACCESSIBILITY_OUTPUT_LOG")" -ne 6 ]]; then
  echo "cjgui internal renderer verifier: expected six enabled shared-operation actions" >&2
  exit 11
fi
if ! grep -F 'cjgui accessibility probe: success=true' "$ACCESSIBILITY_OUTPUT_LOG" >/dev/null 2>&1; then
  echo "cjgui internal renderer verifier: shared-operation accessibility probe did not report success" >&2
  exit 11
fi

# ---- 6. bounded viewport projection and browsing-intent regression ----
#
# The C side must keep an eight-row rendering bound without treating it as an
# application data bound. This probe verifies the final 8-row viewport of a
# 101-record projection and that Page Up/Down return intent to Cangjie rather
# than mutating native shadow state.
echo "cjgui internal renderer verifier: compiling shared-operation viewport probe"
clang \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -fstack-protector-strong \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  "$VIEWPORT_PROBE_SRC" \
  -L "$BUILD_DIR" \
  -lcjgui_internal_renderer \
  -framework AppKit \
  -framework Metal \
  -framework MetalKit \
  -framework QuartzCore \
  -o "$VIEWPORT_EXECUTABLE"

echo "cjgui internal renderer verifier: running shared-operation viewport probe"
: > "$VIEWPORT_OUTPUT_LOG"
set +e
"$VIEWPORT_EXECUTABLE" 2>&1 | tee "$VIEWPORT_OUTPUT_LOG"
viewport_status=${pipestatus[1]}
set -e
if [[ "$viewport_status" -ne 0 ]]; then
  echo "cjgui internal renderer verifier: viewport probe exit status=$viewport_status" >&2
  exit "$viewport_status"
fi
for expected in \
  'cjgui viewport probe: total=101 visible=8 final_start=93' \
  'cjgui viewport probe: scroll_intents=true' \
  'cjgui viewport probe: success=true'; do
  if ! grep -F "$expected" "$VIEWPORT_OUTPUT_LOG" >/dev/null 2>&1; then
    echo "cjgui internal renderer verifier: missing viewport output line: $expected" >&2
    exit 12
  fi
done

echo "cjgui internal renderer verifier: all assertions passed"
echo "cjgui internal renderer verifier: success=true"
