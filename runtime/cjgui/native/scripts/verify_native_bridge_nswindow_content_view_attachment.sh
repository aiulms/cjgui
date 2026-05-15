#!/usr/bin/env zsh
#
# 维护注释：本脚本是 NSWindow harness content-view attachment probe。
# Truth: 验证 production native bridge 只通过 opaque token 在 main thread 内
# attach / detach NSView 到不可见 NSWindow.contentView，并保持 fail-closed classification。
# Stop-line: 不 visible order，不调用 nextDrawable，不创建 encoder，不 draw，
# 不 commit / present / render，不返回 Class / id / pointer / handle，不新增 public API。
# Same-shape Boundary Brake: content-view attachment probe 不是 drawable-ready、
# visible-ready、backend-ready、render-ready 或 public API permission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-nswindow-content-view-attachment-XXXXXX)"
PROBE_SOURCE="$OUTPUT_DIR/nswindow_content_view_attachment_probe.m"
PROBE_EXECUTABLE="$OUTPUT_DIR/nswindow_content_view_attachment_probe"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui native bridge NSWindow content-view attachment probe: macOS is required" >&2
  exit 2
fi

for symbol in \
  "cjgui_native_bridge_nswindow_harness_create" \
  "cjgui_native_bridge_nswindow_harness_destroy" \
  "cjgui_native_bridge_nswindow_harness_token_classify" \
  "cjgui_native_bridge_nswindow_harness_table_occupied_count" \
  "cjgui_native_bridge_nsview_create" \
  "cjgui_native_bridge_nsview_destroy" \
  "cjgui_native_bridge_nsview_token_classify" \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_nswindow_harness_content_view_attach" \
  "cjgui_native_bridge_nswindow_harness_content_view_detach" \
  "cjgui_native_bridge_nswindow_harness_content_view_attachment_classify" \
  "cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify" \
  "cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify" \
  "cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread" \
  "cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui native bridge NSWindow content-view attachment probe: missing callable $symbol" >&2
    exit 3
  fi
done

if grep -E 'makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|drawPrimitives|commit\]|presentDrawable|present\]|uintptr_t|__bridge|CFBridging|^[[:space:]]*(Class|id|void[[:space:]]\*)[[:space:]]+cjgui_' "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui native bridge NSWindow content-view attachment probe: forbidden visible/render/pointer surface found" >&2
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
  echo "cjgui native bridge NSWindow content-view attachment probe: clang not found" >&2
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
  echo "cjgui native bridge NSWindow content-view attachment probe: SDKROOT not found" >&2
  exit 6
fi

cat > "$PROBE_SOURCE" <<'CJGUI_NATIVE_BRIDGE_NSWINDOW_CONTENT_VIEW_ATTACHMENT_PROBE'
#import <pthread.h>
#import <stdint.h>
#import <stdio.h>
#import "cjgui_native_bridge.h"

typedef struct BackgroundContentViewResult {
    int32_t attach_status;
    int32_t detach_status;
    uint64_t window_token;
    uint64_t view_token;
} BackgroundContentViewResult;

static void *background_attach(void *context) {
    BackgroundContentViewResult *result = (BackgroundContentViewResult *)context;
    result->attach_status =
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            result->window_token,
            result->view_token
        );
    return NULL;
}

static void *background_detach(void *context) {
    BackgroundContentViewResult *result = (BackgroundContentViewResult *)context;
    result->detach_status =
        cjgui_native_bridge_nswindow_harness_content_view_detach(
            result->window_token,
            result->view_token
        );
    return NULL;
}

int main(void) {
    printf("cjgui native bridge NSWindow content-view attachment probe: requested=true\n");
    uint32_t window_count_before =
        cjgui_native_bridge_nswindow_harness_table_occupied_count();
    uint32_t view_count_before = cjgui_native_bridge_nsview_table_occupied_count();
    uint64_t window_token = 0;
    uint64_t view_token = 0;
    int32_t window_create =
        cjgui_native_bridge_nswindow_harness_create(&window_token);
    int32_t view_create = cjgui_native_bridge_nsview_create(&view_token);
    BackgroundContentViewResult background = {
        0,
        0,
        window_token,
        view_token
    };
    pthread_t attach_thread;
    pthread_create(&attach_thread, NULL, background_attach, &background);
    pthread_join(attach_thread, NULL);
    int32_t attach_required =
        cjgui_native_bridge_nswindow_harness_content_view_attach_requires_main_thread();
    int32_t visible_order_blocked =
        cjgui_native_bridge_nswindow_harness_content_view_visible_order_still_blocked();
    int32_t next_drawable_blocked =
        cjgui_native_bridge_nswindow_harness_next_drawable_still_blocked();
    int32_t invalid_attach =
        cjgui_native_bridge_nswindow_harness_content_view_attach(0, view_token);
    int32_t attach_status =
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            window_token,
            view_token
        );
    int32_t attached_class =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            window_token,
            view_token
        );
    int32_t double_attach =
        cjgui_native_bridge_nswindow_harness_content_view_attach(
            window_token,
            view_token
        );
    int32_t double_attach_class =
        cjgui_native_bridge_nswindow_harness_content_view_double_attach_classify(
            window_token,
            view_token
        );
    int32_t window_destroy_while_attached =
        cjgui_native_bridge_nswindow_harness_destroy(window_token);
    int32_t view_destroy_while_attached = cjgui_native_bridge_nsview_destroy(view_token);
    pthread_t detach_thread;
    pthread_create(&detach_thread, NULL, background_detach, &background);
    pthread_join(detach_thread, NULL);
    int32_t detach_status =
        cjgui_native_bridge_nswindow_harness_content_view_detach(
            window_token,
            view_token
        );
    int32_t detached_class =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            window_token,
            view_token
        );
    int32_t double_detach =
        cjgui_native_bridge_nswindow_harness_content_view_detach(
            window_token,
            view_token
        );
    int32_t double_detach_class =
        cjgui_native_bridge_nswindow_harness_content_view_double_detach_classify(
            window_token,
            view_token
        );
    int32_t view_destroy = cjgui_native_bridge_nsview_destroy(view_token);
    int32_t window_destroy =
        cjgui_native_bridge_nswindow_harness_destroy(window_token);
    int32_t stale_window_class =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            window_token,
            view_token
        );
    int32_t stale_view_class =
        cjgui_native_bridge_nswindow_harness_content_view_attachment_classify(
            0,
            view_token
        );
    uint32_t window_count_after =
        cjgui_native_bridge_nswindow_harness_table_occupied_count();
    uint32_t view_count_after = cjgui_native_bridge_nsview_table_occupied_count();
    int32_t window_final_class =
        cjgui_native_bridge_nswindow_harness_token_classify(window_token);
    int32_t view_final_class = cjgui_native_bridge_nsview_token_classify(view_token);

    int create_observed = window_create == 0 &&
        view_create == 0 &&
        window_token != 0 &&
        view_token != 0;
    int background_attach_denied = background.attach_status == -381;
    int attach_observed = attach_status == 0 && attached_class == 380;
    int double_attach_observed =
        double_attach == -388 && double_attach_class == -388;
    int destroy_before_detach_denied =
        window_destroy_while_attached == -390 &&
        view_destroy_while_attached == -391;
    int background_detach_denied = background.detach_status == -381;
    int detach_observed = detach_status == 0 && detached_class == -380;
    int double_detach_observed =
        double_detach == -389 && double_detach_class == -389;
    int invalid_fail_closed = invalid_attach == -382 && stale_view_class == -382;
    int stale_fail_closed = stale_window_class == -383;
    int count_cleanup_observed =
        window_count_before == 0 &&
        view_count_before == 0 &&
        window_count_after == 0 &&
        view_count_after == 0 &&
        window_final_class == -363 &&
        view_final_class == -43;
    int main_thread_required_observed = attach_required == -381;
    int still_blocked_observed =
        visible_order_blocked == -392 && next_drawable_blocked == -369;
    int destroy_cleanup_observed = window_destroy == 0 && view_destroy == 0;

    printf("cjgui native bridge NSWindow content-view attachment probe: create_tokens_observed=%s\n", create_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: background_attach_denied_observed=%s\n", background_attach_denied ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: attach_observed=%s\n", attach_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: double_attach_fail_closed_observed=%s\n", double_attach_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: destroy_before_detach_denied_observed=%s\n", destroy_before_detach_denied ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: background_detach_denied_observed=%s\n", background_detach_denied ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: detach_observed=%s\n", detach_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: double_detach_fail_closed_observed=%s\n", double_detach_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: invalid_tokens_fail_closed_observed=%s\n", invalid_fail_closed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: stale_tokens_fail_closed_observed=%s\n", stale_fail_closed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: occupied_count_cleanup_observed=%s\n", count_cleanup_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: main_thread_required_observed=%s\n", main_thread_required_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: still_blocked_observed=%s\n", still_blocked_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: destroy_cleanup_observed=%s\n", destroy_cleanup_observed ? "true" : "false");
    printf("cjgui native bridge NSWindow content-view attachment probe: visible_order_called=false\n");
    printf("cjgui native bridge NSWindow content-view attachment probe: next_drawable_called=false\n");
    printf("cjgui native bridge NSWindow content-view attachment probe: render_encoder_created=false\n");
    printf("cjgui native bridge NSWindow content-view attachment probe: commit_present_called=false\n");
    printf("cjgui native bridge NSWindow content-view attachment probe: pointer_returned=false\n");
    printf("cjgui native bridge NSWindow content-view attachment probe: public_api_modified=false\n");

    int success = create_observed &&
        background_attach_denied &&
        attach_observed &&
        double_attach_observed &&
        destroy_before_detach_denied &&
        background_detach_denied &&
        detach_observed &&
        double_detach_observed &&
        invalid_fail_closed &&
        stale_fail_closed &&
        count_cleanup_observed &&
        main_thread_required_observed &&
        still_blocked_observed &&
        destroy_cleanup_observed;
    if (success) {
        printf("cjgui native bridge NSWindow content-view attachment probe: success=true reason=none\n");
        return 0;
    }
    printf("cjgui native bridge NSWindow content-view attachment probe: success=false reason=value_mismatch\n");
    return 1;
}
CJGUI_NATIVE_BRIDGE_NSWINDOW_CONTENT_VIEW_ATTACHMENT_PROBE

echo "cjgui native bridge NSWindow content-view attachment probe: output=$OUTPUT_DIR"
echo "cjgui native bridge NSWindow content-view attachment probe: sdkroot=$CJ_GUI_SDKROOT"
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
