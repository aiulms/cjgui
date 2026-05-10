#!/usr/bin/env zsh
#
# Owner: platform object real NSView allocation feasibility probe。
# Truth: 只在 isolated temporary program 中验证主线程零尺寸 NSView allocation 可行性。
# Stop-line: 不修改 production bridge / cjpm config，不返回 pointer，不保存 NSView，
# 不创建 window / application / layer，不导入 Metal。
# Same-shape Boundary Brake: feasibility 只是 isolated allocation evidence，
# 不是 production object table、native handle、backend-ready 或 public API permission。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nsview-allocation-feasibility-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/nsview_allocation_feasibility.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/nsview_allocation_feasibility"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge nsview allocation feasibility probe: macOS is required" >&2
  exit 2
fi

if [[ ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui native bridge nsview allocation feasibility probe: missing production native bridge" >&2
  exit 3
fi

if ! grep -F '#import <AppKit/AppKit.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview allocation feasibility probe: AppKit import boundary is missing" >&2
  exit 4
fi

if grep -E '#import <(Cocoa/Cocoa|Metal/Metal)\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview allocation feasibility probe: production bridge must not import Cocoa / Metal" >&2
  exit 5
fi

if grep -E '\[[[:space:]]*(NSWindow|NSApplication|CALayer|CAMetalLayer)[[:space:]]+(alloc|new|init)\]|^[[:space:]]*static[[:space:]]+(NSWindow|NSApplication|CALayer|CAMetalLayer|Class|id)[[:space:]]|^[[:space:]]*(Class|id|void[[:space:]]*\*|uintptr_t)[[:space:]]+cjgui_|MTLDevice|MTLCommandQueue|nextDrawable|commandBuffer|commit|present' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview allocation feasibility probe: production bridge contains forbidden allocation / storage / pointer token" >&2
  exit 6
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
  echo "cjgui native bridge nsview allocation feasibility probe: clang not found" >&2
  exit 7
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge nsview allocation feasibility probe: SDKROOT not found" >&2
  exit 8
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_NSVIEW_ALLOCATION_FEASIBILITY_PROBE'
#import <AppKit/AppKit.h>
#include <pthread.h>
#include <stdio.h>

static void *cjgui_background_thread_gate_probe(void *context) {
    int *backgroundDenied = (int *)context;
    *backgroundDenied = pthread_main_np() == 1 ? 0 : 1;
    return NULL;
}

int main(void) {
    printf("cjgui native bridge nsview allocation feasibility probe: requested=true\n");
    printf("cjgui native bridge nsview allocation feasibility probe: route=isolated_temporary_program\n");

    int mainThreadObserved = pthread_main_np() == 1 ? 1 : 0;
    int nsviewAllocationObserved = 0;
    int immediateCleanupObserved = 0;

    if (mainThreadObserved == 1) {
        @autoreleasepool {
            NSRect zeroFrame = NSMakeRect(0.0, 0.0, 0.0, 0.0);
            NSView *temporaryView = [[NSView alloc] initWithFrame:zeroFrame];
            nsviewAllocationObserved = temporaryView != nil ? 1 : 0;
            temporaryView = nil;
        }
        immediateCleanupObserved = nsviewAllocationObserved;
    }

    int backgroundThreadDeniedObserved = 0;
    pthread_t backgroundThread;
    if (pthread_create(&backgroundThread, NULL, cjgui_background_thread_gate_probe, &backgroundThreadDeniedObserved) == 0) {
        pthread_join(backgroundThread, NULL);
    }

    int success = mainThreadObserved == 1 &&
        nsviewAllocationObserved == 1 &&
        immediateCleanupObserved == 1 &&
        backgroundThreadDeniedObserved == 1;

    printf("cjgui native bridge nsview allocation feasibility probe: main_thread_observed=%s\n", mainThreadObserved == 1 ? "true" : "false");
    printf("cjgui native bridge nsview allocation feasibility probe: nsview_allocation_observed=%s\n", nsviewAllocationObserved == 1 ? "true" : "false");
    printf("cjgui native bridge nsview allocation feasibility probe: immediate_cleanup_observed=%s\n", immediateCleanupObserved == 1 ? "true" : "false");
    printf("cjgui native bridge nsview allocation feasibility probe: background_thread_allocation_denied=true\n");
    printf("cjgui native bridge nsview allocation feasibility probe: pointer_returned=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: native_handle_returned=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: nsview_saved=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: window_created=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: application_created=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: layer_created=false\n");
    printf("cjgui native bridge nsview allocation feasibility probe: metal_imported=false\n");

    if (success) {
        printf("cjgui native bridge nsview allocation feasibility probe: success=true reason=none\n");
        return 0;
    }

    printf("cjgui native bridge nsview allocation feasibility probe: success=false reason=allocation_or_thread_gate_failed\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_NSVIEW_ALLOCATION_FEASIBILITY_PROBE

if grep -E '#import <Metal/Metal\.h>|NSWindow|NSApplication|CALayer|MTLDevice|MTLCommandQueue|uintptr_t|return[[:space:]]+temporaryView' "$PROBE_SOURCE" >/dev/null 2>&1; then
  echo "cjgui native bridge nsview allocation feasibility probe: temporary source crossed object / pointer stop-line" >&2
  exit 9
fi

echo "cjgui native bridge nsview allocation feasibility probe: output=$OUTPUT_DIR"
echo "cjgui native bridge nsview allocation feasibility probe: sdkroot=$CJ_GUI_SDKROOT"
echo "cjgui native bridge nsview allocation feasibility probe: compiling isolated feasibility executable"

"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  "$PROBE_SOURCE" \
  -framework AppKit \
  -framework QuartzCore \
  -o "$PROBE_EXECUTABLE"

"$PROBE_EXECUTABLE"
