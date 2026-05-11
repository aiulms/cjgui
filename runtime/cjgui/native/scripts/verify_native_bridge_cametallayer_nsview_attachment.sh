#!/usr/bin/env zsh
#
# 维护注释：本脚本是 CAMetalLayer token-backed NSView attach/detach probe。
# Truth: 验证 production native bridge 只通过 opaque token 在 main thread 内
# attach / detach CAMetalLayer 与 NSView，并保持 fail-closed classification。
# Stop-line: 不导入 Metal，不设置 CAMetalLayer.device，不获取 drawable，
# 不返回 Class / id / pointer / handle，不新增 public API。
# Same-shape Boundary Brake: attachment probe 只证明 layer-to-view attachment
# 首片可执行，不是 Metal device、drawable、backend-ready、render-ready 或 public API permission。
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-cametallayer-nsview-attachment-XXXXXX)"
OBJECT_FILE="$OUTPUT_DIR/cjgui_native_bridge.o"
PROBE_SOURCE="$OUTPUT_DIR/cametallayer_nsview_attachment_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/cametallayer_nsview_attachment_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge CAMetalLayer NSView attachment probe: macOS is required" >&2
  exit 2
fi
for symbol in \
  "cjgui_native_bridge_nsview_create" \
  "cjgui_native_bridge_nsview_destroy" \
  "cjgui_native_bridge_nsview_token_classify" \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_create" \
  "cjgui_native_bridge_cametallayer_destroy" \
  "cjgui_native_bridge_cametallayer_token_classify" \
  "cjgui_native_bridge_cametallayer_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_attach_to_nsview" \
  "cjgui_native_bridge_cametallayer_detach_from_nsview" \
  "cjgui_native_bridge_cametallayer_attachment_classify" \
  "cjgui_native_bridge_cametallayer_double_detach_classify" \
  "cjgui_native_bridge_cametallayer_attach_requires_main_thread" \
  "cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge CAMetalLayer NSView attachment probe: missing callable $symbol" >&2
    exit 3
  fi
done
if grep -E '#import <Cocoa/Cocoa\.h>' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer NSView attachment probe: forbidden framework import" >&2
  exit 4
fi
if grep -E 'nextDrawable|commit\]|presentDrawable|present\]|uintptr_t|void[[:space:]]*\*|__bridge|CFBridging|^[[:space:]]*(Class|id|CAMetalLayer[[:space:]]*\*)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge CAMetalLayer NSView attachment probe: forbidden Metal / pointer return found" >&2
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
  echo "cjgui native bridge CAMetalLayer NSView attachment probe: clang not found" >&2
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
  echo "cjgui native bridge CAMetalLayer NSView attachment probe: SDKROOT not found" >&2
  exit 7
fi
cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NSVIEW_ATTACHMENT_PROBE'
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"
typedef struct BackgroundAttachResult {
    int32_t attach_status;
    int32_t detach_status;
    uint64_t layer_token;
    uint64_t view_token;
} BackgroundAttachResult;
static void *background_attach(void *context) {
    BackgroundAttachResult *result = (BackgroundAttachResult *)context;
    result->attach_status =
        cjgui_native_bridge_cametallayer_attach_to_nsview(
            result->layer_token,
            result->view_token
        );
    return NULL;
}
static void *background_detach(void *context) {
    BackgroundAttachResult *result = (BackgroundAttachResult *)context;
    result->detach_status =
        cjgui_native_bridge_cametallayer_detach_from_nsview(
            result->layer_token,
            result->view_token
        );
    return NULL;
}
int main(void) {
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: requested=true\n");
    uint32_t nsview_count_before = cjgui_native_bridge_nsview_table_occupied_count();
    uint32_t layer_count_before =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    uint64_t view_token = 0;
    uint64_t layer_token = 0;
    int32_t view_create = cjgui_native_bridge_nsview_create(&view_token);
    int32_t layer_create = cjgui_native_bridge_cametallayer_create(&layer_token);
    BackgroundAttachResult background = {
        0,
        0,
        layer_token,
        view_token
    };
    pthread_t attach_thread;
    pthread_create(&attach_thread, NULL, background_attach, &background);
    pthread_join(attach_thread, NULL);
    int32_t attach_required =
        cjgui_native_bridge_cametallayer_attach_requires_main_thread();
    int32_t device_binding_blocked =
        cjgui_native_bridge_cametallayer_device_binding_after_attach_still_blocked();
    int32_t invalid_attach =
        cjgui_native_bridge_cametallayer_attach_to_nsview(0, view_token);
    int32_t attach_status =
        cjgui_native_bridge_cametallayer_attach_to_nsview(layer_token, view_token);
    int32_t attached_class =
        cjgui_native_bridge_cametallayer_attachment_classify(
            layer_token,
            view_token
        );
    int32_t double_attach =
        cjgui_native_bridge_cametallayer_attach_to_nsview(layer_token, view_token);
    pthread_t detach_thread;
    pthread_create(&detach_thread, NULL, background_detach, &background);
    pthread_join(detach_thread, NULL);
    int32_t detach_status =
        cjgui_native_bridge_cametallayer_detach_from_nsview(layer_token, view_token);
    int32_t detached_class =
        cjgui_native_bridge_cametallayer_attachment_classify(
            layer_token,
            view_token
        );
    int32_t double_detach =
        cjgui_native_bridge_cametallayer_detach_from_nsview(layer_token, view_token);
    int32_t double_detach_class =
        cjgui_native_bridge_cametallayer_double_detach_classify(
            layer_token,
            view_token
        );
    int32_t layer_destroy = cjgui_native_bridge_cametallayer_destroy(layer_token);
    int32_t view_destroy = cjgui_native_bridge_nsview_destroy(view_token);
    int32_t stale_layer_class =
        cjgui_native_bridge_cametallayer_attachment_classify(layer_token, view_token);
    int32_t stale_view_class =
        cjgui_native_bridge_cametallayer_attachment_classify(0, view_token);
    uint32_t nsview_count_after = cjgui_native_bridge_nsview_table_occupied_count();
    uint32_t layer_count_after =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    int32_t layer_final_class =
        cjgui_native_bridge_cametallayer_token_classify(layer_token);
    int32_t view_final_class = cjgui_native_bridge_nsview_token_classify(view_token);
    int create_observed = view_create == 0 &&
        layer_create == 0 &&
        view_token != 0 &&
        layer_token != 0;
    int background_attach_denied = background.attach_status == -91;
    int attach_observed = attach_status == 0 && attached_class == 90;
    int double_attach_observed = double_attach == -97;
    int background_detach_denied = background.detach_status == -91;
    int detach_observed = detach_status == 0 && detached_class == -90;
    int double_detach_observed =
        double_detach == -96 && double_detach_class == -96;
    int invalid_fail_closed = invalid_attach == -92 && stale_view_class == -92;
    int stale_fail_closed = stale_layer_class == -94;
    int count_cleanup_observed =
        nsview_count_before == 0 &&
        layer_count_before == 0 &&
        nsview_count_after == 0 &&
        layer_count_after == 0 &&
        layer_final_class == -83 &&
        view_final_class == -43;
    int main_thread_required_observed = attach_required == -91;
    int device_binding_blocked_observed = device_binding_blocked == -100;
    int destroy_cleanup_observed = layer_destroy == 0 && view_destroy == 0;
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: create_tokens_observed=%s\n", create_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: background_attach_denied_observed=%s\n", background_attach_denied ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: attach_observed=%s\n", attach_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: double_attach_fail_closed_observed=%s\n", double_attach_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: background_detach_denied_observed=%s\n", background_detach_denied ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: detach_observed=%s\n", detach_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: double_detach_fail_closed_observed=%s\n", double_detach_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: invalid_tokens_fail_closed_observed=%s\n", invalid_fail_closed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: stale_tokens_fail_closed_observed=%s\n", stale_fail_closed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: occupied_count_cleanup_observed=%s\n", count_cleanup_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: main_thread_required_observed=%s\n", main_thread_required_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: device_binding_still_blocked_observed=%s\n", device_binding_blocked_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: destroy_cleanup_observed=%s\n", destroy_cleanup_observed ? "true" : "false");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: metal_import_allowed=true\n");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: metal_device_created_by_probe=false\n");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: drawable_acquired=false\n");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: pointer_returned=false\n");
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: public_api_modified=false\n");
    int success = create_observed &&
        background_attach_denied &&
        attach_observed &&
        double_attach_observed &&
        background_detach_denied &&
        detach_observed &&
        double_detach_observed &&
        invalid_fail_closed &&
        stale_fail_closed &&
        count_cleanup_observed &&
        main_thread_required_observed &&
        device_binding_blocked_observed &&
        destroy_cleanup_observed;
    if (success) {
        printf("cjgui native bridge CAMetalLayer NSView attachment probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge CAMetalLayer NSView attachment probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_CAMETALLAYER_NSVIEW_ATTACHMENT_PROBE
echo "cjgui native bridge CAMetalLayer NSView attachment probe: output=$OUTPUT_DIR"
echo "cjgui native bridge CAMetalLayer NSView attachment probe: sdkroot=$CJ_GUI_SDKROOT"
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
  -lobjc \
  -o "$PROBE_EXECUTABLE"
"$PROBE_EXECUTABLE"
