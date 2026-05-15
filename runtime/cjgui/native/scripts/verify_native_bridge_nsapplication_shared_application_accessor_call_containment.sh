#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 NSApplication shared-application accessor call
# native side-effect containment no-call slice。
# Truth: 只验证 production native bridge 暴露 deterministic integer
# containment facts。
# Stop-line: 不调用 application singleton accessor，不创建 application，不
# activation，不运行 event loop，不 order front，不获取 drawable，不创建
# encoder，不 draw，不 commit / present / render，不返回 Class / id / pointer /
# handle。
# Same-shape Boundary Brake: containment guard 不是 application-ready、
# visible-ready、drawable-ready、render-ready、backend-ready 或 public API
# permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-accessor-call-containment-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/accessor_call_containment_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/accessor_call_containment_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge NSApplication shared-application accessor call containment probe: macOS is required" >&2
  exit 2
fi

for symbol in \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked" \
  "cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge NSApplication shared-application accessor call containment probe: missing callable $symbol" >&2
    exit 3
  fi
done

if grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|commit\]|presentDrawable|present\]|uintptr_t|__bridge|CFBridging|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_|(NSApplication|CALayer)[[:space:]]*\*|\[[[:space:]]*(NSApplication|CALayer)[[:space:]]+(alloc|new|init)\]' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge NSApplication shared-application accessor call containment probe: forbidden visible/render/pointer surface found" >&2
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
  echo "cjgui native bridge NSApplication shared-application accessor call containment probe: clang not found" >&2
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
  echo "cjgui native bridge NSApplication shared-application accessor call containment probe: SDKROOT not found" >&2
  exit 6
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_ACCESSOR_CALL_CONTAINMENT_PROBE'
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"

static int require_equal_i32(const char *name, int32_t actual, int32_t expected) {
    if (actual == expected) {
        printf("cjgui native bridge NSApplication shared-application accessor call containment probe: %s=ok value=%d\n", name, actual);
        return 0;
    }
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: %s=bad actual=%d expected=%d\n", name, actual, expected);
    return 1;
}

int main(void) {
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: requested=true\n");
    int failures = 0;
    failures += require_equal_i32(
        "accessor_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_accessor_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACCESSOR_BLOCKED
    );
    failures += require_equal_i32(
        "no_singleton_accessor_call",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_no_singleton_accessor_call(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_NO_SINGLETON_ACCESSOR_CALL
    );
    failures += require_equal_i32(
        "singleton_creation_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_singleton_creation_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_SINGLETON_CREATION_BLOCKED
    );
    failures += require_equal_i32(
        "main_thread_required",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_main_thread_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_MAIN_THREAD_REQUIRED
    );
    failures += require_equal_i32(
        "bounded_run_loop_required",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_bounded_run_loop_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_BOUNDED_RUN_LOOP_REQUIRED
    );
    failures += require_equal_i32(
        "auto_close_required",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_auto_close_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_AUTO_CLOSE_REQUIRED
    );
    failures += require_equal_i32(
        "teardown_before_visible_required",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_teardown_before_visible_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_TEARDOWN_BEFORE_VISIBLE_REQUIRED
    );
    failures += require_equal_i32(
        "non_user_visible_required",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_non_user_visible_required(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_NON_USER_VISIBLE_REQUIRED
    );
    failures += require_equal_i32(
        "application_side_effect_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_application_side_effect_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_APPLICATION_SIDE_EFFECT_BLOCKED
    );
    failures += require_equal_i32(
        "activation_policy_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_policy_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACTIVATION_POLICY_BLOCKED
    );
    failures += require_equal_i32(
        "activation_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_activation_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_ACTIVATION_BLOCKED
    );
    failures += require_equal_i32(
        "event_loop_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_event_loop_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_EVENT_LOOP_BLOCKED
    );
    failures += require_equal_i32(
        "visible_order_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_visible_order_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_VISIBLE_ORDER_BLOCKED
    );
    failures += require_equal_i32(
        "drawable_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_drawable_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_DRAWABLE_BLOCKED
    );
    failures += require_equal_i32(
        "render_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_render_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_RENDER_BLOCKED
    );
    failures += require_equal_i32(
        "backend_ready_truth_blocked",
        cjgui_native_bridge_nsapplication_shared_application_accessor_call_containment_backend_ready_truth_blocked(),
        CJGUI_NATIVE_BRIDGE_NSAPPLICATION_SHARED_APPLICATION_ACCESSOR_CALL_CONTAINMENT_BACKEND_READY_TRUTH_BLOCKED
    );
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: application_singleton_accessor_called=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: application_created=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: activation_called=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: event_loop_started=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: order_front_called=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: next_drawable_called=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: render_encoder_created=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: commit_present_called=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: pointer_returned=false\n");
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: public_api_modified=false\n");
    if (failures == 0) {
        printf("cjgui native bridge NSApplication shared-application accessor call containment probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge NSApplication shared-application accessor call containment probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_ACCESSOR_CALL_CONTAINMENT_PROBE

echo "cjgui native bridge NSApplication shared-application accessor call containment probe: output=$OUTPUT_DIR"
echo "cjgui native bridge NSApplication shared-application accessor call containment probe: sdkroot=$CJ_GUI_SDKROOT"
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
