#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 范围：本脚本验证 isolated visible-window environment probe facts，并输出
# 可复核 result envelope。Metal device 为 nil 时必须显式分类，不能把
# nil-equality 解释成 device-bound / display-backed truth。
# 停止线：production runtime 只允许 token-backed NSWindow harness first slice；
# isolated probe 不调用 nextDrawable，不 present，不创建 command queue / encoder，不提交 GPU work，
# 不返回 native pointer。
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui drawable visible-window environment probe: macOS is required" >&2
  exit 1
fi
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
HEADER_PATH="${NATIVE_DIR}/cjgui_native_bridge.h"
SOURCE_PATH="${NATIVE_DIR}/cjgui_native_bridge.m"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-native-bridge-drawable-env.XXXXXX")"
SUMMARY_PATH="${TMP_DIR}/summary.txt"
BIN_PATH="${TMP_DIR}/drawable_environment_probe"
PROBE_SOURCE="${TMP_DIR}/drawable_environment_probe.m"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT
required_symbols=(
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked"
  "cjgui_native_bridge_metal_device_command_queue_still_blocked"
  "cjgui_native_bridge_cametallayer_device_binding_requires_main_thread"
  "cjgui_native_bridge_nsview_table_occupied_count"
  "cjgui_native_bridge_cametallayer_table_occupied_count"
  "cjgui_native_bridge_metal_device_table_occupied_count"
)
for symbol in "${required_symbols[@]}"; do
  if ! grep -q "$symbol" "$HEADER_PATH"; then
    echo "missing header symbol: $symbol" >&2
    exit 1
  fi
  if ! grep -q "$symbol" "$SOURCE_PATH"; then
    echo "missing source symbol: $symbol" >&2
    exit 1
  fi
done
if grep -Eq 'nextDrawable|presentDrawable|present]|MTLRenderCommandEncoder|renderCommandEncoder|commit]' "$SOURCE_PATH"; then
  echo "forbidden drawable / command submission path found in production bridge" >&2
  exit 1
fi
if grep -Eq 'NSApplication[[:space:]]+sharedApplication|makeKeyAndOrderFront|orderFront' "$SOURCE_PATH"; then
  echo "forbidden production visible window / application creation path found" >&2
  exit 1
fi
if grep -Eq '^[[:space:]]*(void[[:space:]]*\*|id|Class)[[:space:]]+cjgui_native_bridge_|uintptr_t[[:space:]]+cjgui_native_bridge_' "$HEADER_PATH"; then
  echo "forbidden pointer/id/Class return in native bridge C ABI header" >&2
  exit 1
fi
cat > "$PROBE_SOURCE" <<'OBJC'
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#include <pthread.h>
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"
static int expect_zero_u32(const char *name, uint32_t value) {
  if (value != 0) {
    fprintf(stderr, "%s expected zero, got %u\n", name, value);
    return 1;
  }
  return 0;
}
static int expect_negative(const char *name, int32_t value) {
  if (value >= 0) {
    fprintf(stderr, "%s expected fail-closed negative value, got %d\n", name, value);
    return 1;
  }
  return 0;
}
static void pump_bounded_run_loop(NSTimeInterval seconds) {
  NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:seconds];
  while ([deadline timeIntervalSinceNow] > 0.0) {
    @autoreleasepool {
      NSDate *slice = [NSDate dateWithTimeIntervalSinceNow:0.01];
      [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:slice];
    }
  }
}
int main(void) {
  int failures = 0;
  @autoreleasepool {
    uint32_t view_count_before = cjgui_native_bridge_nsview_table_occupied_count();
    uint32_t layer_count_before =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    uint32_t device_count_before =
        cjgui_native_bridge_metal_device_table_occupied_count();
    int32_t drawable_blocked =
        cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked();
    int32_t command_queue_blocked =
        cjgui_native_bridge_metal_device_command_queue_still_blocked();
    int32_t binding_main_thread_required =
        cjgui_native_bridge_cametallayer_device_binding_requires_main_thread();
    failures += expect_zero_u32("nsview table count before", view_count_before);
    failures += expect_zero_u32(
        "cametallayer table count before", layer_count_before);
    failures += expect_zero_u32(
        "metal device table count before", device_count_before);
    failures += expect_negative(
        "drawable acquisition still blocked", drawable_blocked);
    failures += expect_negative("command queue still blocked", command_queue_blocked);
    failures += expect_negative(
        "layer/device binding main-thread gate",
        binding_main_thread_required);
    int main_thread_observed = pthread_main_np() == 1;
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSRect frame = NSMakeRect(64.0, 64.0, 160.0, 120.0);
    NSUInteger style =
        NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
        NSWindowStyleMaskMiniaturizable;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:style
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 160.0, 120.0)];
    CAMetalLayer *layer = [CAMetalLayer layer];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    int isolated_metal_device_available = device != nil;
    if (window == nil || view == nil || layer == nil || device == nil) {
      failures += 1;
    }
    [window setTitle:@"cjgui drawable environment probe"];
    [window setReleasedWhenClosed:NO];
    [window setContentView:view];
    view.wantsLayer = YES;
    view.layer = layer;
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(160.0, 120.0);
    [window makeKeyAndOrderFront:nil];
    [app activateIgnoringOtherApps:YES];
    pump_bounded_run_loop(0.20);
    int isolated_window_created = window != nil;
    int isolated_window_visible = window.isVisible ? 1 : 0;
    int isolated_view_attached = view.window == window ? 1 : 0;
    int isolated_layer_attached = view.layer == layer ? 1 : 0;
    int isolated_device_bound =
        isolated_metal_device_available && layer.device == device ? 1 : 0;
    int display_backed_layer =
        isolated_window_visible && isolated_view_attached &&
        isolated_layer_attached && isolated_metal_device_available &&
        isolated_device_bound &&
        layer.drawableSize.width > 0.0 && layer.drawableSize.height > 0.0;
    if (!main_thread_observed || !isolated_window_created ||
        !isolated_window_visible || !isolated_view_attached ||
        !isolated_layer_attached || !isolated_device_bound ||
        !display_backed_layer) {
      failures += 1;
    }
    layer.device = nil;
    view.layer = nil;
    view.wantsLayer = NO;
    [window orderOut:nil];
    [window close];
    pump_bounded_run_loop(0.05);
    int cleanup_window_hidden = !window.isVisible;
    int cleanup_view_layer_disabled = view.wantsLayer ? 0 : 1;
    int cleanup_layer_device_cleared = layer.device == nil;
    int cleanup_observed =
        cleanup_window_hidden && cleanup_view_layer_disabled &&
        cleanup_layer_device_cleared;
    if (!cleanup_observed) {
      failures += 1;
    }
    uint32_t view_count_after = cjgui_native_bridge_nsview_table_occupied_count();
    uint32_t layer_count_after =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    uint32_t device_count_after =
        cjgui_native_bridge_metal_device_table_occupied_count();
    failures += expect_zero_u32("nsview table count after", view_count_after);
    failures += expect_zero_u32(
        "cametallayer table count after", layer_count_after);
    failures += expect_zero_u32(
        "metal device table count after", device_count_after);
    const char *visible_window_environment_failure_domain =
        failures == 0 ? "none" :
        (!isolated_metal_device_available ?
            "metal_device_unavailable" : "probe_state_mismatch");
    printf("drawable_visible_window_probe_route=isolated_visible_window_environment\n");
    printf("isolated_visible_window_probe_executed=true\n");
    printf("production_window_created=false\n");
    printf("isolated_window_created=%s\n",
           isolated_window_created ? "true" : "false");
    printf("isolated_window_visible_observed=%s\n",
           isolated_window_visible ? "true" : "false");
    printf("isolated_view_attached_observed=%s\n",
           isolated_view_attached ? "true" : "false");
    printf("isolated_cametallayer_attached_observed=%s\n",
           isolated_layer_attached ? "true" : "false");
    printf("isolated_metal_device_available=%s\n",
           isolated_metal_device_available ? "true" : "false");
    printf("isolated_metal_device_bound_observed=%s\n",
           isolated_device_bound ? "true" : "false");
    printf("display_backed_layer_observed=%s\n",
           display_backed_layer ? "true" : "false");
    printf("bounded_run_loop_observed=true\n");
    printf("cleanup_observed=%s\n", cleanup_observed ? "true" : "false");
    printf("cleanup_window_hidden=%s\n",
           cleanup_window_hidden ? "true" : "false");
    printf("cleanup_view_layer_disabled=%s\n",
           cleanup_view_layer_disabled ? "true" : "false");
    printf("cleanup_layer_device_cleared=%s\n",
           cleanup_layer_device_cleared ? "true" : "false");
    printf("next_drawable_called=false\n");
    printf("present_called=false\n");
    printf("command_buffer_created=false\n");
    printf("gpu_work_submitted=false\n");
    printf("drawable_acquisition_still_blocked=%d\n", drawable_blocked);
    printf("command_queue_still_blocked=%d\n", command_queue_blocked);
    printf("binding_main_thread_required=%d\n", binding_main_thread_required);
    printf("view_table_occupied_before=%u\n", view_count_before);
    printf("layer_table_occupied_before=%u\n", layer_count_before);
    printf("device_table_occupied_before=%u\n", device_count_before);
    printf("view_table_occupied_after=%u\n", view_count_after);
    printf("layer_table_occupied_after=%u\n", layer_count_after);
    printf("device_table_occupied_after=%u\n", device_count_after);
    printf("failure_count=%d\n", failures);
    printf("visible_window_environment_failure_domain=%s\n",
           visible_window_environment_failure_domain);
    printf("drawable_visible_window_probe=%s\n",
           failures == 0 ? "passed" : "failed");
    printf("drawable_environment_visibility_probe=%s\n",
           failures == 0 ? "passed" : "failed");
  }
  return failures == 0 ? 0 : 1;
}
OBJC
if grep -Eq 'nextDrawable|presentDrawable|present]|MTLRenderCommandEncoder|renderCommandEncoder|commit]' "$PROBE_SOURCE"; then
  echo "forbidden drawable / command submission path found in isolated visible-window probe" >&2
  exit 1
fi
clang -fobjc-arc -ObjC -I"$NATIVE_DIR" \
  "$SOURCE_PATH" "$PROBE_SOURCE" \
  -framework AppKit -framework QuartzCore -framework Metal -lobjc \
  -o "$BIN_PATH"
"$BIN_PATH" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
