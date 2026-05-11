#!/usr/bin/env zsh
#
# 维护注释：本脚本是 CAMetalLayer allocation without attachment feasibility probe。
# Truth: 验证 production native bridge 可在 main thread 创建未 attach、无 device 的
# CAMetalLayer 临时对象并立即清理为整数事实。
# Stop-line: 本 probe 不执行 attach；允许后续 attachment C ABI 存在，但仍不导入 Metal，
# 不创建 drawable，不返回 Class / id / pointer / handle。
# Same-shape Boundary Brake: allocation feasibility 不等于 attachment、Metal device、
# backend-ready、render-ready、GPU submission 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-allocation-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
PROBE_SOURCE="$OUTPUT_DIR/cametallayer_allocation_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/cametallayer_allocation_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer allocation probe: macOS is required" >&2
  exit 2
fi
for symbol in \
  "cjgui_native_bridge_cametallayer_allocation_feasible" \
  "cjgui_native_bridge_cametallayer_allocation_requires_main_thread" \
  "cjgui_native_bridge_cametallayer_allocation_no_attach_admission" \
  "cjgui_native_bridge_cametallayer_allocation_device_binding_blocked" \
  "cjgui_native_bridge_cametallayer_allocation_feasibility_probe"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge CAMetalLayer allocation probe: missing callable $symbol" >&2
    exit 3
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer allocation probe: forbidden framework import" >&2
  exit 4
fi
if grep -E 'nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging|^[[:space:]]*(Class|id)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer allocation probe: forbidden Metal / pointer token found" >&2
  exit 5
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
  echo "cjgui native bridge CAMetalLayer allocation probe: clang not found" >&2
  exit 6
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui native bridge CAMetalLayer allocation probe: SDKROOT not found" >&2
  exit 7
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_PROBE'
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"
static void *background_probe(void *context) {
    int32_t *result = (int32_t *)context;
    *result = cjgui_native_bridge_cametallayer_allocation_feasibility_probe();
    return NULL;
}
int main(void) {
    printf("cjgui native bridge CAMetalLayer allocation probe: requested=true\n");
    int32_t feasible = cjgui_native_bridge_cametallayer_allocation_feasible();
    int32_t requires_main_thread =
        cjgui_native_bridge_cametallayer_allocation_requires_main_thread();
    int32_t no_attach =
        cjgui_native_bridge_cametallayer_allocation_no_attach_admission();
    int32_t device_blocked =
        cjgui_native_bridge_cametallayer_allocation_device_binding_blocked();
    int32_t main_thread_probe =
        cjgui_native_bridge_cametallayer_allocation_feasibility_probe();
    int32_t background_value = 0;
    pthread_t background_thread;
    pthread_create(&background_thread, NULL, background_probe,
        &background_value);
    pthread_join(background_thread, NULL);
    int success = feasible == 60 &&
        requires_main_thread == -60 &&
        no_attach == 61 &&
        device_blocked == -62 &&
        main_thread_probe == 62 &&
        background_value == -60;
    printf("cjgui native bridge CAMetalLayer allocation probe: allocation_feasible_observed=%s\n", feasible == 60 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: main_thread_required_observed=%s\n", requires_main_thread == -60 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: no_attach_admission_observed=%s\n", no_attach == 61 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: device_binding_blocked_observed=%s\n", device_blocked == -62 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: main_thread_feasibility_observed=%s\n", main_thread_probe == 62 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: background_thread_denied_observed=%s\n", background_value == -60 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer allocation probe: layer_attached=false\n");
    printf("cjgui native bridge CAMetalLayer allocation probe: device_set=false\n");
    printf("cjgui native bridge CAMetalLayer allocation probe: drawable_acquired=false\n");
    printf("cjgui native bridge CAMetalLayer allocation probe: pointer_returned=false\n");
    if (success) {
        printf("cjgui native bridge CAMetalLayer allocation probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge CAMetalLayer allocation probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_ALLOCATION_PROBE
echo "cjgui native bridge CAMetalLayer allocation probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer allocation probe: sdkroot=$CJ_GUI_SDKROOT"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -I "$NATIVE_DIR" \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -I "$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$OBJECT_FILE" \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
