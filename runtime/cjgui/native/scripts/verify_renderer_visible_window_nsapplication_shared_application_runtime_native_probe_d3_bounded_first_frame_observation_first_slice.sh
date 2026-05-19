#!/usr/bin/env zsh
#
# 维护注释：本脚本执行 bounded isolated first-frame observation first slice。
# 它在 stage115 同形的 visible-window / CAMetalLayer / Metal draw+present 后，
# 只生成 probe-local window capture 与 frame-hash summary；不持久化图片或 hash，
# 不输出 hash 值，不把结果升级为 production render truth。
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: macOS is required" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
mkdir -p "${TMPDIR:-/tmp}"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-stage117-bounded-first-frame-observation.XXXXXX")"
PROBE_SOURCE="$OUTPUT_DIR/bounded_first_frame_observation_probe.m"
PROBE_BINARY="$OUTPUT_DIR/bounded_first_frame_observation_probe"
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
  "cjgui_native_bridge_command_buffer_commit_still_blocked" \
  "cjgui_native_bridge_command_buffer_encoder_creation_still_blocked" \
  "cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked" \
  "cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked" \
  "cjgui_native_bridge_vertex_buffer_draw_still_blocked" \
  "cjgui_native_bridge_shader_draw_still_blocked" \
  "cjgui_native_bridge_nswindow_harness_present_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: missing production bridge fact $symbol" >&2
    exit 3
  fi
done

if grep -Ev '^[[:space:]]*(/\*|\*|//)' "$SOURCE_FILE" \
  | grep -E 'nextDrawable|presentDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|commit\]|waitUntilCompleted|present\]|screencapture|CGDisplayCreateImage|CGBitmapContextCreate' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: production native bridge must not contain drawable/render/capture calls" >&2
  exit 4
fi

if grep -E '^[[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_native_bridge_' "$HEADER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: production bridge must not expose pointer/id/Class returns" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: clang not found" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation first slice: SDKROOT not found" >&2
  exit 7
fi

cat > "$PROBE_SOURCE" <<'OBJC'
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <dispatch/dispatch.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include "cjgui_native_bridge.h"

typedef struct CjguiProbeVertex {
  float position[2];
  float color[4];
} CjguiProbeVertex;

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
    int32_t production_commit_blocked =
        cjgui_native_bridge_command_buffer_commit_still_blocked();
    int32_t production_encoder_blocked =
        cjgui_native_bridge_command_buffer_encoder_creation_still_blocked();
    int32_t production_pipeline_binding_blocked =
        cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked();
    int32_t production_vertex_binding_blocked =
        cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked();
    int32_t production_vertex_draw_blocked =
        cjgui_native_bridge_vertex_buffer_draw_still_blocked();
    int32_t production_shader_draw_blocked =
        cjgui_native_bridge_shader_draw_still_blocked();
    int32_t production_present_blocked =
        cjgui_native_bridge_nswindow_harness_present_still_blocked();

    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSRect frame = NSMakeRect(232.0, 232.0, 180.0, 140.0);
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:style
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    NSView *view =
        [[NSView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 180.0, 140.0)];
    CAMetalLayer *layer = [CAMetalLayer layer];
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    int isolated_metal_device_available = device != nil;
    if (window == nil || view == nil || layer == nil || device == nil) {
      failures += 1;
    }

    [window setTitle:@"cjgui bounded first-frame observation"];
    [window setReleasedWhenClosed:NO];
    [window setContentView:view];
    view.wantsLayer = YES;
    view.layer = layer;
    layer.device = device;
    layer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;
    layer.drawableSize = CGSizeMake(180.0, 140.0);
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
    id<MTLTexture> texture = drawable != nil ? drawable.texture : nil;
    int drawable_texture_observed = texture != nil;
    if (!drawable_texture_observed) {
      failures += 1;
    }

    id<MTLCommandQueue> queue = device != nil ? [device newCommandQueue] : nil;
    id<MTLCommandBuffer> command_buffer =
        queue != nil ? [queue commandBuffer] : nil;
    int command_queue_created = queue != nil;
    int command_buffer_created = command_buffer != nil;
    if (!command_queue_created || !command_buffer_created) {
      failures += 1;
    }

    MTLRenderPassDescriptor *descriptor =
        [MTLRenderPassDescriptor renderPassDescriptor];
    MTLRenderPassColorAttachmentDescriptor *attachment =
        [descriptor.colorAttachments objectAtIndexedSubscript:0];
    int render_pass_descriptor_created = descriptor != nil;
    int color_attachment_configured = 0;
    if (descriptor != nil && attachment != nil && texture != nil) {
      attachment.texture = texture;
      attachment.loadAction = MTLLoadActionClear;
      attachment.storeAction = MTLStoreActionStore;
      attachment.clearColor = MTLClearColorMake(0.01, 0.04, 0.08, 1.0);
      color_attachment_configured = attachment.texture == texture;
    }
    if (!render_pass_descriptor_created || !color_attachment_configured) {
      failures += 1;
    }

    NSString *source =
        @"#include <metal_stdlib>\n"
         "using namespace metal;\n"
         "struct Vertex { float2 position; float4 color; };\n"
         "struct Out { float4 position [[position]]; float4 color; };\n"
         "vertex Out cjgui_vertex_main(uint vid [[vertex_id]], const device Vertex *vertices [[buffer(0)]]) {\n"
         "  Out out;\n"
         "  out.position = float4(vertices[vid].position, 0.0, 1.0);\n"
         "  out.color = vertices[vid].color;\n"
         "  return out;\n"
         "}\n"
         "fragment float4 cjgui_fragment_main(Out in [[stage_in]]) {\n"
         "  return in.color;\n"
         "}\n";
    NSError *library_error = nil;
    id<MTLLibrary> library =
        device != nil ? [device newLibraryWithSource:source options:nil error:&library_error] : nil;
    id<MTLFunction> vertex_function =
        library != nil ? [library newFunctionWithName:@"cjgui_vertex_main"] : nil;
    id<MTLFunction> fragment_function =
        library != nil ? [library newFunctionWithName:@"cjgui_fragment_main"] : nil;
    MTLRenderPipelineDescriptor *pipeline_descriptor =
        [[MTLRenderPipelineDescriptor alloc] init];
    pipeline_descriptor.vertexFunction = vertex_function;
    pipeline_descriptor.fragmentFunction = fragment_function;
    pipeline_descriptor.colorAttachments[0].pixelFormat =
        MTLPixelFormatBGRA8Unorm;
    NSError *pipeline_error = nil;
    id<MTLRenderPipelineState> pipeline_state =
        device != nil ? [device newRenderPipelineStateWithDescriptor:pipeline_descriptor
                                                               error:&pipeline_error] : nil;
    CjguiProbeVertex vertices[3] = {
        {{-0.68f, -0.62f}, {0.96f, 0.12f, 0.16f, 1.0f}},
        {{ 0.68f, -0.62f}, {0.08f, 0.76f, 0.42f, 1.0f}},
        {{ 0.00f,  0.70f}, {0.20f, 0.38f, 1.0f, 1.0f}},
    };
    id<MTLBuffer> vertex_buffer =
        device != nil ? [device newBufferWithBytes:vertices
                                            length:sizeof(vertices)
                                           options:MTLResourceStorageModeShared] : nil;
    int shader_library_created = library != nil;
    int shader_functions_created =
        vertex_function != nil && fragment_function != nil;
    int pipeline_descriptor_configured =
        pipeline_descriptor.vertexFunction == vertex_function &&
        pipeline_descriptor.fragmentFunction == fragment_function &&
        pipeline_descriptor.colorAttachments[0].pixelFormat ==
            MTLPixelFormatBGRA8Unorm;
    int pipeline_state_created = pipeline_state != nil;
    int vertex_buffer_created =
        vertex_buffer != nil && vertex_buffer.length == sizeof(vertices);
    if (!shader_library_created || !shader_functions_created ||
        !pipeline_descriptor_configured || !pipeline_state_created ||
        !vertex_buffer_created) {
      failures += 1;
    }

    id<MTLRenderCommandEncoder> encoder = nil;
    int render_command_encoder_created = 0;
    int pipeline_state_bound = 0;
    int vertex_buffer_bound = 0;
    int draw_called = 0;
    int end_encoding_called = 0;
    int present_branch_selected = 0;
    int no_present_branch_selected = 0;
    int present_after_encoding_before_commit = 0;
    int present_called = 0;
    int drawable_present_scheduled = 0;
    int commit_called = 0;
    __block int completion_handler_called = 0;
    int bounded_completion_wait_completed = 0;
    int command_buffer_status_completed = 0;
    int command_buffer_error_nil = 0;
    dispatch_semaphore_t completion_semaphore = dispatch_semaphore_create(0);

    if (command_buffer != nil && descriptor != nil &&
        color_attachment_configured && drawable != nil) {
      encoder = [command_buffer renderCommandEncoderWithDescriptor:descriptor];
      render_command_encoder_created = encoder != nil;
      if (encoder != nil && pipeline_state != nil && vertex_buffer != nil) {
        [encoder setRenderPipelineState:pipeline_state];
        pipeline_state_bound = 1;
        [encoder setVertexBuffer:vertex_buffer offset:0 atIndex:0];
        vertex_buffer_bound = 1;
        [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        draw_called = 1;
        [encoder endEncoding];
        end_encoding_called = 1;
        present_branch_selected = 1;
        [command_buffer presentDrawable:drawable];
        present_called = 1;
        drawable_present_scheduled = 1;
        present_after_encoding_before_commit =
            end_encoding_called && present_called && !commit_called;
        [command_buffer addCompletedHandler:^(id<MTLCommandBuffer> completed_buffer) {
          (void)completed_buffer;
          completion_handler_called = 1;
          dispatch_semaphore_signal(completion_semaphore);
        }];
        [command_buffer commit];
        commit_called = 1;
        long wait_result = dispatch_semaphore_wait(
            completion_semaphore,
            dispatch_time(DISPATCH_TIME_NOW, 2LL * NSEC_PER_SEC));
        bounded_completion_wait_completed = wait_result == 0;
        command_buffer_status_completed =
            command_buffer.status == MTLCommandBufferStatusCompleted;
        command_buffer_error_nil = command_buffer.error == nil;
      }
    } else {
      no_present_branch_selected = 1;
    }
    int bounded_gpu_submission_completed =
        commit_called && completion_handler_called &&
        bounded_completion_wait_completed && command_buffer_status_completed &&
        command_buffer_error_nil;
    int bounded_drawable_present_scheduled =
        present_branch_selected && present_after_encoding_before_commit &&
        present_called && drawable_present_scheduled && commit_called &&
        bounded_gpu_submission_completed;
    if (!render_command_encoder_created || !pipeline_state_bound ||
        !vertex_buffer_bound || !draw_called || !end_encoding_called ||
        !bounded_drawable_present_scheduled) {
      failures += 1;
    }

    pump_bounded_run_loop(0.35);
    int first_frame_capture_attempted = 0;
    int window_capture_requested = 0;
    int window_id_observed = 0;
    int user_visible_window_capture_source = 0;
    int frame_capture_image_created = 0;
    int frame_hash_computed = 0;
    int frame_hash_nonzero = 0;
    int captured_nonzero_pixel_sample_count = 0;
    size_t frame_pixel_width = 0;
    size_t frame_pixel_height = 0;
    if (bounded_drawable_present_scheduled) {
      first_frame_capture_attempted = 1;
      window_capture_requested = 1;
      CGWindowID window_id = (CGWindowID)[window windowNumber];
      window_id_observed = window_id != 0;
      NSRect window_frame = [window frame];
      NSScreen *screen = window.screen != nil ? window.screen : [NSScreen mainScreen];
      NSRect screen_frame = screen.frame;
      CGFloat capture_x = window_frame.origin.x;
      CGFloat capture_y = NSMaxY(screen_frame) - NSMaxY(window_frame);
      NSString *capture_path =
          [NSTemporaryDirectory() stringByAppendingPathComponent:
              @"cjgui-stage117-first-frame-observation.png"];
      NSString *rect_arg =
          [NSString stringWithFormat:@"%.0f,%.0f,%.0f,%.0f",
                                     capture_x,
                                     capture_y,
                                     window_frame.size.width,
                                     window_frame.size.height];
      NSTask *capture_task = [[NSTask alloc] init];
      capture_task.launchPath = @"/usr/sbin/screencapture";
      capture_task.arguments = @[@"-x", @"-R", rect_arg, capture_path];
      @try {
        [capture_task launch];
        [capture_task waitUntilExit];
      } @catch (NSException *exception) {
        (void)exception;
      }
      NSData *frame_data = [NSData dataWithContentsOfFile:capture_path];
      frame_capture_image_created =
          capture_task.terminationStatus == 0 && frame_data != nil &&
          frame_data.length > 0;
      user_visible_window_capture_source = frame_capture_image_created;
      if (frame_capture_image_created) {
        NSImage *frame_image = [[NSImage alloc] initWithData:frame_data];
        if (frame_image != nil) {
          NSSize frame_size = frame_image.size;
          frame_pixel_width = (size_t)frame_size.width;
          frame_pixel_height = (size_t)frame_size.height;
        }
        const uint8_t *bytes = (const uint8_t *)frame_data.bytes;
        size_t buffer_size = frame_data.length;
        if (bytes != NULL && buffer_size > 0) {
          uint64_t hash_accumulator = 1469598103934665603ULL;
          for (size_t i = 0; i < buffer_size; i++) {
            hash_accumulator ^= bytes[i];
            hash_accumulator *= 1099511628211ULL;
          }
          size_t stride = buffer_size < 256 ? 1 : buffer_size / 256;
          for (size_t offset = 0; offset < buffer_size; offset += stride) {
            if (bytes[offset] != 0) {
              captured_nonzero_pixel_sample_count += 1;
            }
          }
          frame_hash_computed = 1;
          frame_hash_nonzero = hash_accumulator != 1469598103934665603ULL;
        }
      }
      [[NSFileManager defaultManager] removeItemAtPath:capture_path error:nil];
    }
    int frame_hash_persisted = 0;
    int frame_hash_value_logged = 0;
    int baseline_compared = 0;
    int first_frame_observed =
        bounded_drawable_present_scheduled && first_frame_capture_attempted &&
        window_capture_requested && window_id_observed &&
        user_visible_window_capture_source && frame_capture_image_created &&
        frame_hash_computed && frame_hash_nonzero &&
        captured_nonzero_pixel_sample_count > 0 &&
        !frame_hash_persisted && !frame_hash_value_logged &&
        !baseline_compared;
    if (!first_frame_observed) {
      failures += 1;
    }

    encoder = nil;
    vertex_buffer = nil;
    pipeline_state = nil;
    pipeline_descriptor = nil;
    fragment_function = nil;
    vertex_function = nil;
    library = nil;
    attachment.texture = nil;
    command_buffer = nil;
    queue = nil;
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
        (!isolated_metal_device_available ? "metal_device_unavailable" :
         (bounded_drawable_present_scheduled && !frame_capture_image_created ?
            "window_capture_unavailable" : "first_frame_observation_first_slice_failed"));
    printf("first_frame_observation_first_slice_route=bounded_isolated_first_slice\n");
    printf("isolated_visible_window_probe_executed=true\n");
    printf("isolated_metal_device_available=%s\n",
           isolated_metal_device_available ? "true" : "false");
    printf("next_drawable_called=%s\n",
           next_drawable_called ? "true" : "false");
    printf("drawable_texture_observed=%s\n",
           drawable_texture_observed ? "true" : "false");
    printf("command_queue_created=%s\n", command_queue_created ? "true" : "false");
    printf("command_buffer_created=%s\n", command_buffer_created ? "true" : "false");
    printf("render_pass_descriptor_created=%s\n",
           render_pass_descriptor_created ? "true" : "false");
    printf("color_attachment_configured=%s\n",
           color_attachment_configured ? "true" : "false");
    printf("render_command_encoder_created=%s\n",
           render_command_encoder_created ? "true" : "false");
    printf("shader_library_created=%s\n",
           shader_library_created ? "true" : "false");
    printf("shader_functions_created=%s\n",
           shader_functions_created ? "true" : "false");
    printf("pipeline_descriptor_configured=%s\n",
           pipeline_descriptor_configured ? "true" : "false");
    printf("pipeline_state_created=%s\n",
           pipeline_state_created ? "true" : "false");
    printf("vertex_buffer_created=%s\n",
           vertex_buffer_created ? "true" : "false");
    printf("pipeline_state_bound=%s\n",
           pipeline_state_bound ? "true" : "false");
    printf("vertex_buffer_bound=%s\n",
           vertex_buffer_bound ? "true" : "false");
    printf("draw_called=%s\n", draw_called ? "true" : "false");
    printf("end_encoding_called=%s\n", end_encoding_called ? "true" : "false");
    printf("present_branch_selected=%s\n",
           present_branch_selected ? "true" : "false");
    printf("no_present_branch_selected=%s\n",
           no_present_branch_selected ? "true" : "false");
    printf("present_after_encoding_before_commit=%s\n",
           present_after_encoding_before_commit ? "true" : "false");
    printf("present_called=%s\n", present_called ? "true" : "false");
    printf("drawable_present_scheduled=%s\n",
           drawable_present_scheduled ? "true" : "false");
    printf("commit_called=%s\n", commit_called ? "true" : "false");
    printf("completion_handler_called=%s\n",
           completion_handler_called ? "true" : "false");
    printf("bounded_completion_wait_completed=%s\n",
           bounded_completion_wait_completed ? "true" : "false");
    printf("command_buffer_status_completed=%s\n",
           command_buffer_status_completed ? "true" : "false");
    printf("command_buffer_error_nil=%s\n",
           command_buffer_error_nil ? "true" : "false");
    printf("bounded_gpu_submission_completed=%s\n",
           bounded_gpu_submission_completed ? "true" : "false");
    printf("bounded_drawable_present_scheduled=%s\n",
           bounded_drawable_present_scheduled ? "true" : "false");
    printf("first_frame_capture_attempted=%s\n",
           first_frame_capture_attempted ? "true" : "false");
    printf("window_capture_requested=%s\n",
           window_capture_requested ? "true" : "false");
    printf("window_id_observed=%s\n", window_id_observed ? "true" : "false");
    printf("user_visible_window_capture_source=%s\n",
           user_visible_window_capture_source ? "true" : "false");
    printf("frame_capture_image_created=%s\n",
           frame_capture_image_created ? "true" : "false");
    printf("frame_pixel_width=%zu\n", frame_pixel_width);
    printf("frame_pixel_height=%zu\n", frame_pixel_height);
    printf("frame_hash_computed=%s\n",
           frame_hash_computed ? "true" : "false");
    printf("frame_hash_nonzero=%s\n", frame_hash_nonzero ? "true" : "false");
    printf("captured_nonzero_pixel_sample_count=%d\n",
           captured_nonzero_pixel_sample_count);
    printf("frame_hash_persisted=false\n");
    printf("frame_hash_value_logged=false\n");
    printf("baseline_compared=false\n");
    printf("first_frame_observed=%s\n",
           first_frame_observed ? "true" : "false");
    printf("production_commit_still_blocked=%d\n", production_commit_blocked);
    printf("production_encoder_creation_still_blocked=%d\n",
           production_encoder_blocked);
    printf("production_pipeline_binding_still_blocked=%d\n",
           production_pipeline_binding_blocked);
    printf("production_vertex_binding_still_blocked=%d\n",
           production_vertex_binding_blocked);
    printf("production_vertex_draw_still_blocked=%d\n",
           production_vertex_draw_blocked);
    printf("production_shader_draw_still_blocked=%d\n",
           production_shader_draw_blocked);
    printf("production_present_still_blocked=%d\n", production_present_blocked);
    printf("drawable_presented=false\n");
    printf("gpu_work_submitted=%s\n", commit_called ? "true" : "false");
    printf("bounded_probe_gpu_work_submitted=%s\n",
           commit_called ? "true" : "false");
    printf("production_present_call=false\n");
    printf("production_gpu_submission=false\n");
    printf("production_render_executed=false\n");
    printf("production_render_truth=false\n");
    printf("production_draw_call=false\n");
    printf("result_envelope_promoted_to_production_truth=false\n");
    printf("backend_ready_truth=false\n");
    printf("native_bridge_expansion=false\n");
    printf("production_public_c_abi_added=false\n");
    printf("renderer_state_write=false\n");
    printf("cleanup_observed=%s\n", cleanup_observed ? "true" : "false");
    printf("bridge_table_counts_clean=%s\n",
           bridge_table_counts_clean ? "true" : "false");
    printf("failure_count=%d\n", failures);
    printf("first_frame_observation_first_slice_failure_domain=%s\n",
           failure_domain);
    printf("first_frame_observation_first_slice_probe=%s\n",
           failures == 0 ? "passed" : "failed");
  }
  return failures == 0 ? 0 : 20;
}
OBJC

"$CLANG_BIN" \
  -fobjc-arc \
  -fblocks \
  -fmodules \
  -fmodules-cache-path="$CLANG_CACHE_DIR" \
  -isysroot "$CJ_GUI_SDKROOT" \
  -I"$NATIVE_DIR" \
  "$PROBE_SOURCE" \
  "$SOURCE_FILE" \
  -framework AppKit \
  -framework QuartzCore \
  -framework Metal \
  -framework CoreGraphics \
  -lobjc \
  -o "$PROBE_BINARY"

"$PROBE_BINARY" | tee "$SUMMARY_PATH"
echo "summary_path=$SUMMARY_PATH"
