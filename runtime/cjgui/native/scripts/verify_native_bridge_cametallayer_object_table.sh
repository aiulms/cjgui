#!/usr/bin/env zsh
#
# 维护注释：本脚本是 CAMetalLayer token-backed table shell probe。
# Truth: 验证 production native bridge 暴露 fixed-capacity CAMetalLayer table
# metadata / fail-closed classification facts。
# Stop-line: 本 probe 不执行 attach；允许后续 attachment C ABI 存在，但仍不设置
# device，不获取 drawable，不返回 Class / id / pointer / handle。
# Same-shape Boundary Brake: table shell 不等于 retention、attachment、Metal
# device、backend-ready、render-ready、GPU submission 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-table-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
PROBE_SOURCE="$OUTPUT_DIR/cametallayer_table_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/cametallayer_table_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer table probe: macOS is required" >&2
  exit 2
fi
for symbol in \
  "cjgui_native_bridge_cametallayer_table_capacity" \
  "cjgui_native_bridge_cametallayer_table_enabled" \
  "cjgui_native_bridge_cametallayer_table_empty" \
  "cjgui_native_bridge_cametallayer_table_token_classify" \
  "cjgui_native_bridge_cametallayer_table_allocation_still_blocked" \
  "cjgui_native_bridge_cametallayer_table_destroy_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge CAMetalLayer table probe: missing callable $symbol" >&2
    exit 3
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer table probe: forbidden framework import" >&2
  exit 4
fi
if grep -E 'nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging|^[[:space:]]*(Class|id)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer table probe: forbidden Metal / pointer token found" >&2
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
  echo "cjgui native bridge CAMetalLayer table probe: clang not found" >&2
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
  echo "cjgui native bridge CAMetalLayer table probe: SDKROOT not found" >&2
  exit 7
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_PROBE'
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"
int main(void) {
    printf("cjgui native bridge CAMetalLayer table probe: requested=true\n");
    uint32_t capacity = cjgui_native_bridge_cametallayer_table_capacity();
    uint32_t enabled = cjgui_native_bridge_cametallayer_table_enabled();
    int32_t empty = cjgui_native_bridge_cametallayer_table_empty();
    int32_t invalid_class =
        cjgui_native_bridge_cametallayer_table_token_classify(0);
    int32_t allocation_blocked =
        cjgui_native_bridge_cametallayer_table_allocation_still_blocked();
    int32_t destroy_blocked =
        cjgui_native_bridge_cametallayer_table_destroy_still_blocked();
    int success = capacity == 4 &&
        enabled == 1 &&
        empty == 70 &&
        invalid_class == 0 &&
        allocation_blocked == -71 &&
        destroy_blocked == -72;
    printf("cjgui native bridge CAMetalLayer table probe: fixed_capacity_observed=%s\n", capacity == 4 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: enabled_observed=%s\n", enabled == 1 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: empty_fact_observed=%s\n", empty == 70 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: invalid_token_fail_closed_observed=%s\n", invalid_class == 0 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: allocation_still_blocked_observed=%s\n", allocation_blocked == -71 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: destroy_still_blocked_observed=%s\n", destroy_blocked == -72 ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer table probe: layer_attached=false\n");
    printf("cjgui native bridge CAMetalLayer table probe: device_set=false\n");
    printf("cjgui native bridge CAMetalLayer table probe: drawable_acquired=false\n");
    printf("cjgui native bridge CAMetalLayer table probe: pointer_returned=false\n");
    if (success) {
        printf("cjgui native bridge CAMetalLayer table probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge CAMetalLayer table probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_TABLE_PROBE
echo "cjgui native bridge CAMetalLayer table probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer table probe: sdkroot=$CJ_GUI_SDKROOT"
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
