#!/usr/bin/env zsh
#
# 维护注释：本脚本是 CAMetalLayer token-backed create/destroy first-slice probe。
# Truth: 验证 production native bridge 只通过 opaque token 创建、持有、销毁固定容量
# CAMetalLayer，并保持 fail-closed classification。
# Stop-line: 本 probe 不执行 attach；允许后续 attachment C ABI 存在，但仍不设置
# device，不获取 drawable，不返回 Class / id / pointer / handle，不导入 Metal。
# Same-shape Boundary Brake: create/destroy probe 只证明 layer token lifecycle
# 首片可执行，不是 attachment、Metal device、backend-ready、render-ready 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-create-destroy-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
PROBE_SOURCE="$OUTPUT_DIR/cametallayer_create_destroy_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/cametallayer_create_destroy_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer create/destroy probe: macOS is required" >&2
  exit 2
fi
for symbol in \
  "cjgui_native_bridge_cametallayer_create" \
  "cjgui_native_bridge_cametallayer_destroy" \
  "cjgui_native_bridge_cametallayer_token_classify" \
  "cjgui_native_bridge_cametallayer_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_double_destroy_classify" \
  "cjgui_native_bridge_cametallayer_destroy_requires_main_thread"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge CAMetalLayer create/destroy probe: missing callable $symbol" >&2
    exit 3
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer create/destroy probe: forbidden framework import" >&2
  exit 4
fi
if grep -E 'nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|__bridge|CFBridging|^[[:space:]]*(Class|id|void[[:space:]]*\*)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer create/destroy probe: forbidden Metal / pointer token found" >&2
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
  echo "cjgui native bridge CAMetalLayer create/destroy probe: clang not found" >&2
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
  echo "cjgui native bridge CAMetalLayer create/destroy probe: SDKROOT not found" >&2
  exit 7
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CREATE_DESTROY_PROBE'
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"
typedef struct BackgroundResult {
    int32_t status;
    int32_t classify_after_attempt;
    uint64_t token;
} BackgroundResult;
static void *background_create(void *context) {
    BackgroundResult *result = (BackgroundResult *)context;
    uint64_t token = 0;
    result->status = cjgui_native_bridge_cametallayer_create(&token);
    result->token = token;
    return NULL;
}
static void *background_destroy(void *context) {
    BackgroundResult *result = (BackgroundResult *)context;
    result->status = cjgui_native_bridge_cametallayer_destroy(result->token);
    result->classify_after_attempt =
        cjgui_native_bridge_cametallayer_token_classify(result->token);
    return NULL;
}
int main(void) {
    printf("cjgui native bridge CAMetalLayer create/destroy probe: requested=true\n");
    uint64_t token = 0;
    uint32_t occupied_before =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    int32_t create_status = cjgui_native_bridge_cametallayer_create(&token);
    uint32_t occupied_after_create =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    int32_t valid_classification =
        cjgui_native_bridge_cametallayer_token_classify(token);
    int32_t invalid_destroy_status =
        cjgui_native_bridge_cametallayer_destroy(0);
    int32_t requires_main_thread =
        cjgui_native_bridge_cametallayer_destroy_requires_main_thread();
    BackgroundResult background_destroy_result = {
        0,
        0,
        token
    };
    pthread_t destroy_thread;
    pthread_create(&destroy_thread, NULL, background_destroy,
        &background_destroy_result);
    pthread_join(destroy_thread, NULL);
    int32_t destroy_status = cjgui_native_bridge_cametallayer_destroy(token);
    uint32_t occupied_after_destroy =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    int32_t destroyed_classification =
        cjgui_native_bridge_cametallayer_token_classify(token);
    int32_t double_destroy_status =
        cjgui_native_bridge_cametallayer_destroy(token);
    int32_t double_destroy_classification =
        cjgui_native_bridge_cametallayer_double_destroy_classify(token);
    BackgroundResult background_create_result = {
        0,
        0,
        0
    };
    pthread_t create_thread;
    pthread_create(&create_thread, NULL, background_create,
        &background_create_result);
    pthread_join(create_thread, NULL);
    int pointer_like_token = token >= 0x100000000ULL;
    int create_observed = create_status == 0 && token != 0;
    int valid_observed = valid_classification == 80;
    int occupied_observed =
        occupied_before == 0 && occupied_after_create == 1 &&
        occupied_after_destroy == 0;
    int background_destroy_denied =
        background_destroy_result.status == -81 &&
        background_destroy_result.classify_after_attempt == 80;
    int destroy_observed = destroy_status == 0;
    int destroyed_observed = destroyed_classification == -83;
    int double_destroy_observed =
        double_destroy_status == -86 &&
        double_destroy_classification == -86;
    int invalid_token_observed = invalid_destroy_status == -82;
    int background_create_denied =
        background_create_result.status == -80 &&
        background_create_result.token == 0;
    int requires_main_thread_observed = requires_main_thread == -81;
    int token_not_pointer_observed = pointer_like_token == 0;
    printf("cjgui native bridge CAMetalLayer create/destroy probe: main_thread_create_observed=%s\n", create_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: token_classify_valid_observed=%s\n", valid_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: occupied_count_observed=%s\n", occupied_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: background_destroy_denied_observed=%s\n", background_destroy_denied ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: destroy_observed=%s\n", destroy_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: destroyed_stale_observed=%s\n", destroyed_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: double_destroy_fail_closed_observed=%s\n", double_destroy_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: invalid_token_fail_closed_observed=%s\n", invalid_token_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: background_create_denied_observed=%s\n", background_create_denied ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: destroy_requires_main_thread_observed=%s\n", requires_main_thread_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: token_not_pointer_observed=%s\n", token_not_pointer_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: layer_attached=false\n");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: device_set=false\n");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: drawable_acquired=false\n");
    printf("cjgui native bridge CAMetalLayer create/destroy probe: pointer_returned=false\n");
    int success = create_observed &&
        valid_observed &&
        occupied_observed &&
        background_destroy_denied &&
        destroy_observed &&
        destroyed_observed &&
        double_destroy_observed &&
        invalid_token_observed &&
        background_create_denied &&
        requires_main_thread_observed &&
        token_not_pointer_observed;
    if (success) {
        printf("cjgui native bridge CAMetalLayer create/destroy probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge CAMetalLayer create/destroy probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_CREATE_DESTROY_PROBE
echo "cjgui native bridge CAMetalLayer create/destroy probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer create/destroy probe: sdkroot=$CJ_GUI_SDKROOT"
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
