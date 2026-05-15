#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 NSApplication native guard no-side-effect slice。
# Truth: 只验证 production native bridge 暴露 deterministic integer guard facts。
# Stop-line: 不创建 application，不 activation，不运行 event loop，不 order front，
# 不获取 drawable，不创建 encoder，不 draw，不 commit / present / render，
# 不返回 Class / id / pointer / handle。
# Same-shape Boundary Brake: native guard 不是 application-ready、visible-ready、
# drawable-ready、render-ready、backend-ready 或 public API permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nsapplication-guard-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/nsapplication_guard_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/nsapplication_guard_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge NSApplication guard probe: macOS is required" >&2
  exit 2
fi

for symbol in \
  "cjgui_native_bridge_nsapplication_guard_ownership_required" \
  "cjgui_native_bridge_nsapplication_guard_main_thread_required" \
  "cjgui_native_bridge_nsapplication_guard_creation_deferred" \
  "cjgui_native_bridge_nsapplication_guard_activation_deferred" \
  "cjgui_native_bridge_nsapplication_guard_activation_policy_deferred" \
  "cjgui_native_bridge_nsapplication_guard_event_loop_deferred" \
  "cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required" \
  "cjgui_native_bridge_nsapplication_guard_auto_close_required" \
  "cjgui_native_bridge_nsapplication_guard_headless_fail_closed" \
  "cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked" \
  "cjgui_native_bridge_nsapplication_guard_drawable_still_blocked" \
  "cjgui_native_bridge_nsapplication_guard_render_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge NSApplication guard probe: missing callable $symbol" >&2
    exit 3
  fi
done

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|commit\]|presentDrawable|present\]|uintptr_t|__bridge|CFBridging|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|(NSApplication|CALayer)[[:space:]]*\*|\[[[:space:]]*(NSApplication|CALayer)[[:space:]]+(alloc|new|init)\]' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge NSApplication guard probe: forbidden visible/render/pointer surface found" >&2
  exit 4
fi

if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || true)"
else
  CLANG_BIN=""
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  CLANG_BIN="$(command -v clang || true)"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui native bridge NSApplication guard probe: clang not found" >&2
  exit 5
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge NSApplication guard probe: SDKROOT not found" >&2
  exit 6
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_PROBE'
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"

static int require_equal_i32(const char *name, int32_t actual, int32_t expected) {
    if (actual == expected) {
        printf("cjgui native bridge NSApplication guard probe: %s=ok value=%d\n", name, actual);
        return 0;
    }
    printf("cjgui native bridge NSApplication guard probe: %s=bad actual=%d expected=%d\n", name, actual, expected);
    return 1;
}

int main(void) {
    printf("cjgui native bridge NSApplication guard probe: requested=true\n");
    int failures = 0;
    failures += require_equal_i32(
        "ownership_required",
        cjgui_native_bridge_nsapplication_guard_ownership_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_OWNERSHIP_REQUIRED
    );
    failures += require_equal_i32(
        "main_thread_required",
        cjgui_native_bridge_nsapplication_guard_main_thread_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_MAIN_THREAD_REQUIRED
    );
    failures += require_equal_i32(
        "creation_deferred",
        cjgui_native_bridge_nsapplication_guard_creation_deferred(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_CREATION_DEFERRED
    );
    failures += require_equal_i32(
        "activation_deferred",
        cjgui_native_bridge_nsapplication_guard_activation_deferred(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_ACTIVATION_DEFERRED
    );
    failures += require_equal_i32(
        "activation_policy_deferred",
        cjgui_native_bridge_nsapplication_guard_activation_policy_deferred(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_ACTIVATION_POLICY_DEFERRED
    );
    failures += require_equal_i32(
        "event_loop_deferred",
        cjgui_native_bridge_nsapplication_guard_event_loop_deferred(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_EVENT_LOOP_DEFERRED
    );
    failures += require_equal_i32(
        "bounded_run_loop_required",
        cjgui_native_bridge_nsapplication_guard_bounded_run_loop_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_BOUNDED_RUN_LOOP_REQUIRED
    );
    failures += require_equal_i32(
        "auto_close_required",
        cjgui_native_bridge_nsapplication_guard_auto_close_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_AUTO_CLOSE_REQUIRED
    );
    failures += require_equal_i32(
        "headless_fail_closed",
        cjgui_native_bridge_nsapplication_guard_headless_fail_closed(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_HEADLESS_FAIL_CLOSED
    );
    failures += require_equal_i32(
        "visible_order_still_blocked",
        cjgui_native_bridge_nsapplication_guard_visible_order_still_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_VISIBLE_ORDER_STILL_BLOCKED
    );
    failures += require_equal_i32(
        "drawable_still_blocked",
        cjgui_native_bridge_nsapplication_guard_drawable_still_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_DRAWABLE_STILL_BLOCKED
    );
    failures += require_equal_i32(
        "render_still_blocked",
        cjgui_native_bridge_nsapplication_guard_render_still_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_RENDER_STILL_BLOCKED
    );
    printf("cjgui native bridge NSApplication guard probe: application_created=false\n");
    printf("cjgui native bridge NSApplication guard probe: activation_called=false\n");
    printf("cjgui native bridge NSApplication guard probe: event_loop_started=false\n");
    printf("cjgui native bridge NSApplication guard probe: order_front_called=false\n");
    printf("cjgui native bridge NSApplication guard probe: next_drawable_called=false\n");
    printf("cjgui native bridge NSApplication guard probe: render_encoder_created=false\n");
    printf("cjgui native bridge NSApplication guard probe: commit_present_called=false\n");
    printf("cjgui native bridge NSApplication guard probe: pointer_returned=false\n");
    printf("cjgui native bridge NSApplication guard probe: public_api_modified=false\n");
    if (failures == 0) {
        printf("cjgui native bridge NSApplication guard probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge NSApplication guard probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_NSAPPLICATION_GUARD_PROBE

echo "cjgui native bridge NSApplication guard probe: output=$OUTPUT_DIR"
echo "cjgui native bridge NSApplication guard probe: sdkroot=$CJ_GUI_SDKROOT"
"$CLANG_BIN" \
  -fobjc-arc \
  -isysroot "$CJ_GUI_SDKROOT" \
  -I"$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$SOURCE_FILE" \
  -framework Foundation \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
