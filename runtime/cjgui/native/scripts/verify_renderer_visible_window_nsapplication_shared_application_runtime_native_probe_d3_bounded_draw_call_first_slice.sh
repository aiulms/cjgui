#!/usr/bin/env zsh
#
# 维护注释：本脚本执行 bounded isolated draw-call first slice。它在隔离
# visible-window probe 内复用 stage112 前置形状，绑定 pipeline state 与 static
# triangle vertex buffer 后调用 drawPrimitives，然后在 commit / present 前停住。
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: macOS is required" >&2
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/cjgui-stage113-bounded-draw-call.XXXXXX")"
PROBE_SOURCE="$OUTPUT_DIR/bounded_draw_call_probe.m"
PROBE_BINARY="$OUTPUT_DIR/bounded_draw_call_probe"
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
  "cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked" \
  "cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked" \
  "cjgui_native_bridge_vertex_buffer_draw_still_blocked" \
  "cjgui_native_bridge_shader_draw_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: missing production bridge fact $symbol" >&2
    exit 3
  fi
done

if grep -Ev '^[[:space:]]*(/\*|\*|//)' "$SOURCE_FILE" \
  | grep -E 'nextDrawable|presentDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|commit\]|present\]' >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: production native bridge must not contain drawable/render submission calls" >&2
  exit 4
fi

if grep -E '^[[:space:]]*(Class|id|void[[:space:]]\*|uintptr_t)[[:space:]]+cjgui_native_bridge_' "$HEADER_FILE" >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: production bridge must not expose pointer/id/Class returns" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: clang not found" >&2
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
  echo "cjgui renderer NSApplication runtime native probe D3 bounded draw call first slice: SDKROOT not found" >&2
  exit 7
fi

cat > "$PROBE_SOURCE" <<'OBJC'
#import <AppKit/AppKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#include <stdint.h>
#include <stdio.h>
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
    int32_t production_pipeline_binding_blocked =
        cjgui_native_bridge_pipeline_state_encoder_binding_still_blocked();
    int32_t production_vertex_binding_blocked =
        cjgui_native_bridge_vertex_buffer_encoder_binding_still_blocked();
    int32_t production_vertex_draw_blocked =
        cjgui_native_bridge_vertex_buffer_draw_still_blocked();
    int32_t production_shader_draw_blocked =
        cjgui_native_bridge_shader_draw_still_blocked();

    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    NSRect frame = NSMakeRect(144.0, 144.0, 160.0, 120.0);
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

    [window setTitle:@"cjgui bounded draw call probe"];
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
    id<MTLTexture> texture = drawable != nil ? drawable.texture : nil;
    int drawable_texture_observed = texture != nil;
    if (!drawable_texture_observed) {
      failures += 1;
    }

    id<MTLCommandQueue> queue = device != nil ? [device newCommandQueue] : nil;
    id<MTLCommandBuffer> command_buffer = queue != nil ? [queue commandBuffer] : nil;
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
      attachment.clearColor = MTLClearColorMake(0.01, 0.07, 0.12, 1.0);
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
    pipeline_descriptor.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    NSError *pipeline_error = nil;
    id<MTLRenderPipelineState> pipeline_state =
        device != nil ? [device newRenderPipelineStateWithDescriptor:pipeline_descriptor
                                                               error:&pipeline_error] : nil;
    CjguiProbeVertex vertices[3] = {
        {{-0.65f, -0.55f}, {1.0f, 0.16f, 0.12f, 1.0f}},
        {{ 0.65f, -0.55f}, {0.1f, 0.8f, 0.35f, 1.0f}},
        {{ 0.00f,  0.62f}, {0.2f, 0.45f, 1.0f, 1.0f}},
    };
    id<MTLBuffer> vertex_buffer =
        device != nil ? [device newBufferWithBytes:vertices
                                            length:sizeof(vertices)
                                           options:MTLResourceStorageModeShared] : nil;
    int shader_library_created = library != nil;
    int shader_functions_created = vertex_function != nil && fragment_function != nil;
    int pipeline_descriptor_configured =
        pipeline_descriptor.vertexFunction == vertex_function &&
        pipeline_descriptor.fragmentFunction == fragment_function &&
        pipeline_descriptor.colorAttachments[0].pixelFormat == MTLPixelFormatBGRA8Unorm;
    int pipeline_state_created = pipeline_state != nil;
    int vertex_buffer_created = vertex_buffer != nil && vertex_buffer.length == sizeof(vertices);
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
    if (command_buffer != nil && descriptor != nil && color_attachment_configured) {
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
      }
    }
    if (!render_command_encoder_created || !pipeline_state_bound ||
        !vertex_buffer_bound || !draw_called || !end_encoding_called) {
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
        (!isolated_metal_device_available ?
            "metal_device_unavailable" : "draw_call_first_slice_failed");
    printf("draw_call_first_slice_route=bounded_isolated_first_slice\n");
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
    printf("production_pipeline_binding_still_blocked=%d\n",
           production_pipeline_binding_blocked);
    printf("production_vertex_binding_still_blocked=%d\n",
           production_vertex_binding_blocked);
    printf("production_vertex_draw_still_blocked=%d\n",
           production_vertex_draw_blocked);
    printf("production_shader_draw_still_blocked=%d\n",
           production_shader_draw_blocked);
    printf("commit_called=false\n");
    printf("present_called=false\n");
    printf("gpu_work_submitted=false\n");
    printf("render_executed=false\n");
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
    printf("draw_call_first_slice_failure_domain=%s\n", failure_domain);
    printf("bounded_draw_call_first_slice_probe=%s\n",
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
