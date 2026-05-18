#!/usr/bin/env zsh
#
# 维护注释：本脚本执行 bounded isolated color attachment configuration
# first slice。它在隔离 visible-window probe 内获取 drawable texture，创建
# probe-local MTLRenderPassDescriptor，并只配置 colorAttachments[0]；不创建
# encoder，不 draw / commit / present，不提交 GPU work。
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: macOS is required" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-stage109-bounded-color-attachment-configuration.XXXXXX")"
PROBE_SOURCE="$OUTPUT_DIR/bounded_color_attachment_configuration_probe.m"
PROBE_BINARY="$OUTPUT_DIR/bounded_color_attachment_configuration_probe"
SUMMARY_PATH="$OUTPUT_DIR/summary.txt"
CLANG_CACHE_DIR="$OUTPUT_DIR/clang-cache"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
cleanup() {
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT
mkdir -p "$CLANG_CACHE_DIR"

for symbol in \
  "cjgui_native_bridge_nsview_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_table_occupied_count" \
  "cjgui_native_bridge_metal_device_table_occupied_count" \
  "cjgui_native_bridge_command_queue_table_occupied_count" \
  "cjgui_native_bridge_command_buffer_table_occupied_count" \
  "cjgui_native_bridge_render_pass_descriptor_table_occupied_count" \
  "cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked" \
  "cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked" \
  "cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: missing production bridge fact $symbol" >&2
    exit 3
  fi
done

if grep -E 'nextDrawable|presentDrawable|renderCommandEncoder|drawPrimitives|drawIndexedPrimitives|commit\]|present\]' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: production native bridge must not contain drawable/render submission calls" >&2
  exit 4
fi

if grep -E '^[[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_native_bridge_' "$HEADER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: production bridge must not expose pointer/id/Class returns" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: clang not found" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded color attachment configuration first slice: SDKROOT not found" >&2
  exit 7
fi

cat > "$PROBE_SOURCE" <<'OBJC'
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <stdint.h>
#include <stdio.h>
#include "cjgui_native_bridge.h"

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
    uint32_t queue_count_before =
        cjgui_native_bridge_command_queue_table_occupied_count();
    uint32_t buffer_count_before =
        cjgui_native_bridge_command_buffer_table_occupied_count();
    uint32_t descriptor_count_before =
        cjgui_native_bridge_render_pass_descriptor_table_occupied_count();
    int32_t production_drawable_blocked =
        cjgui_native_bridge_cametallayer_drawable_acquisition_still_blocked();
    int32_t production_color_attachment_blocked =
        cjgui_native_bridge_render_pass_descriptor_color_attachment_still_blocked();
    int32_t production_encoder_blocked =
        cjgui_native_bridge_render_pass_descriptor_encoder_creation_still_blocked();

    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSRect frame = NSMakeRect(96.0, 96.0, 160.0, 120.0);
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
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

    [window setTitle:@"cjgui bounded color attachment configuration probe"];
    [window setReleasedWhenClosed:NO];
    [window setContentView:view];
    view.wantsLayer = YES;
    view.layer = layer;
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(160.0, 120.0);
    if ([layer respondsToSelector:@selector(setAllowsNextDrawableTimeout:)]) {
      layer.allowsNextDrawableTimeout = YES;
    }
    [window makeKeyAndOrderFront:nil];
    [app activateIgnoringOtherApps:YES];
    [window displayIfNeeded];
    [view displayIfNeeded];
    [CATransaction flush];
    pump_bounded_run_loop(0.25);

    int next_drawable_called = 0;
    id<CAMetalDrawable> drawable = nil;
    if (isolated_metal_device_available) {
      next_drawable_called = 1;
      drawable = [layer nextDrawable];
    }
    int drawable_acquired = drawable != nil;
    id<MTLTexture> texture = drawable_acquired ? drawable.texture : nil;
    int drawable_texture_observed = texture != nil;
    NSUInteger drawable_width = texture != nil ? texture.width : 0u;
    NSUInteger drawable_height = texture != nil ? texture.height : 0u;
    if (!drawable_acquired || !drawable_texture_observed ||
        drawable_width == 0u || drawable_height == 0u) {
      failures += 1;
    }

    MTLRenderPassDescriptor *descriptor =
        [MTLRenderPassDescriptor renderPassDescriptor];
    MTLRenderPassColorAttachmentDescriptor *attachment =
        [descriptor.colorAttachments objectAtIndexedSubscript:0];
    int descriptor_created = descriptor != nil;
    int attachment_slot_observed = attachment != nil;
    int color_attachment_configured = 0;
    int attachment_texture_matches_drawable_texture = 0;
    int attachment_load_action_clear = 0;
    int attachment_store_action_store = 0;
    if (descriptor_created && attachment_slot_observed && texture != nil) {
      attachment.texture = texture;
      attachment.loadAction = MTLLoadActionClear;
      attachment.storeAction = MTLStoreActionStore;
      attachment.clearColor = MTLClearColorMake(0.06, 0.11, 0.17, 1.0);
      color_attachment_configured = attachment.texture == texture;
      attachment_texture_matches_drawable_texture = attachment.texture == texture;
      attachment_load_action_clear = attachment.loadAction == MTLLoadActionClear;
      attachment_store_action_store = attachment.storeAction == MTLStoreActionStore;
    }
    if (!descriptor_created || !attachment_slot_observed ||
        !color_attachment_configured ||
        !attachment_texture_matches_drawable_texture ||
        !attachment_load_action_clear || !attachment_store_action_store) {
      failures += 1;
    }

    attachment.texture = nil;
    drawable = nil;
    layer.device = nil;
    view.layer = nil;
    view.wantsLayer = NO;
    [window orderOut:nil];
    [window close];
    pump_bounded_run_loop(0.05);
    int cleanup_observed =
        !window.isVisible && !view.wantsLayer && layer.device == nil &&
        attachment.texture == nil;

    uint32_t view_count_after = cjgui_native_bridge_nsview_table_occupied_count();
    uint32_t layer_count_after =
        cjgui_native_bridge_cametallayer_table_occupied_count();
    uint32_t device_count_after =
        cjgui_native_bridge_metal_device_table_occupied_count();
    uint32_t queue_count_after =
        cjgui_native_bridge_command_queue_table_occupied_count();
    uint32_t buffer_count_after =
        cjgui_native_bridge_command_buffer_table_occupied_count();
    uint32_t descriptor_count_after =
        cjgui_native_bridge_render_pass_descriptor_table_occupied_count();
    int bridge_table_counts_clean =
        view_count_before == view_count_after &&
        layer_count_before == layer_count_after &&
        device_count_before == device_count_after &&
        queue_count_before == queue_count_after &&
        buffer_count_before == buffer_count_after &&
        descriptor_count_before == descriptor_count_after;
    if (!cleanup_observed || !bridge_table_counts_clean) {
      failures += 1;
    }

    const char *failure_domain =
        failures == 0 ? "none" :
        (!isolated_metal_device_available ?
            "metal_device_unavailable" : "color_attachment_configuration_failed");
    printf("color_attachment_configuration_route=bounded_isolated_first_slice\n");
    printf("isolated_visible_window_probe_executed=true\n");
    printf("isolated_metal_device_available=%s\n",
           isolated_metal_device_available ? "true" : "false");
    printf("next_drawable_called=%s\n",
           next_drawable_called ? "true" : "false");
    printf("drawable_acquired=%s\n", drawable_acquired ? "true" : "false");
    printf("drawable_texture_observed=%s\n",
           drawable_texture_observed ? "true" : "false");
    printf("drawable_texture_width=%llu\n",
           (unsigned long long)drawable_width);
    printf("drawable_texture_height=%llu\n",
           (unsigned long long)drawable_height);
    printf("render_pass_descriptor_created=%s\n",
           descriptor_created ? "true" : "false");
    printf("color_attachment_slot_observed=%s\n",
           attachment_slot_observed ? "true" : "false");
    printf("color_attachment_configured=%s\n",
           color_attachment_configured ? "true" : "false");
    printf("attachment_texture_matches_drawable_texture=%s\n",
           attachment_texture_matches_drawable_texture ? "true" : "false");
    printf("attachment_load_action_clear=%s\n",
           attachment_load_action_clear ? "true" : "false");
    printf("attachment_store_action_store=%s\n",
           attachment_store_action_store ? "true" : "false");
    printf("production_drawable_acquisition_still_blocked=%d\n",
           production_drawable_blocked);
    printf("production_color_attachment_still_blocked=%d\n",
           production_color_attachment_blocked);
    printf("encoder_creation_still_blocked=%d\n", production_encoder_blocked);
    printf("encoder_created=false\n");
    printf("draw_called=false\n");
    printf("commit_called=false\n");
    printf("present_called=false\n");
    printf("gpu_work_submitted=false\n");
    printf("render_executed=false\n");
    printf("production_color_attachment_configuration=false\n");
    printf("result_envelope_promoted_to_production_truth=false\n");
    printf("backend_ready_truth=false\n");
    printf("native_bridge_expansion=false\n");
    printf("production_public_c_abi_added=false\n");
    printf("renderer_state_write=false\n");
    printf("cleanup_observed=%s\n", cleanup_observed ? "true" : "false");
    printf("bridge_table_counts_clean=%s\n",
           bridge_table_counts_clean ? "true" : "false");
    printf("failure_count=%d\n", failures);
    printf("color_attachment_configuration_failure_domain=%s\n", failure_domain);
    printf("bounded_color_attachment_configuration_first_slice_probe=%s\n",
           failures == 0 ? "passed" : "failed");
  }
  return failures == 0 ? 0 : 20;
}
OBJC

"$CLANG_BIN" \
  -fobjc-arc \
  -fmodules \
  -fmodules-cache-path="$CLANG_CACHE_DIR" \
  -isysroot "$CJ_GUI_SDKROOT" \
  -I"$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$SOURCE_FILE" \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -lobjc \
  -o "$PROBE_BINARY"

"$PROBE_BINARY" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
