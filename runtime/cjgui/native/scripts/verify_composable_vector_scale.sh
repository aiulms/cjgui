#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}"
OUTPUT_DIR="${CJGUI_VECTOR_SCALE_TMPDIR:-/private/tmp/cjgui-composable-vector-scale-final}"
PROBE="$RUNTIME_DIR/probe/vector_geometry_cache_scale_probe.cj"
mkdir -p "$OUTPUT_DIR/native"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

(
  cd "$RUNTIME_DIR/shared_operation_core"
  SDKROOT="$SDKROOT_PATH" cjpm build --skip-script
)
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_vector_scale.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"
cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" "$RUNTIME_DIR/src/composable_vector_graphics.cj" \
  "$RUNTIME_DIR/src/composable_vector_graphics_component.cj" "$PROBE" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_vector_scale \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/vector_scale_probe" >"$OUTPUT_DIR/compile.log" 2>&1

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/vector_scale_probe" >"$OUTPUT_DIR/result" 2>"$OUTPUT_DIR/stderr.log"
for objects in 16 128 480; do
  [[ "$(rg -c "^CJGUI_VECTOR_SCALE_SAMPLE objects=${objects} " "$OUTPUT_DIR/result")" == 30 ]] || {
    print -u2 -- "vector scale: expected 30 samples for objects=$objects"
    exit 1
  }
  rg -q "^CJGUI_VECTOR_SCALE_RESULT objects=${objects} .*geometry_preparations=.+/.+ .*generic_vertex_bytes=0 .*vector_draws=${objects}/${objects} .*vector_uploads=${objects}/0 .*vector_reuses=0/${objects} .*passed=true$" "$OUTPUT_DIR/result"
done
rg -q '^CJGUI_VECTOR_SCALE_PROBE passed=true$' "$OUTPUT_DIR/result"
{
  print -r -- 'format=1'
  print -r -- "probe=$PROBE"
  print -r -- "probe_sha256=$(shasum -a 256 "$PROBE" | awk '{print $1}')"
  print -r -- "renderer_sha256=$(shasum -a 256 "$RUNTIME_DIR/native/cjgui_internal_renderer.m" | awk '{print $1}')"
  print -r -- "binary=$OUTPUT_DIR/vector_scale_probe"
  print -r -- "binary_sha256=$(shasum -a 256 "$OUTPUT_DIR/vector_scale_probe" | awk '{print $1}')"
  print -r -- "result=$OUTPUT_DIR/result"
  print -r -- "stderr=$OUTPUT_DIR/stderr.log"
  print -r -- 'objects=16,128,480'
  print -r -- 'local_updates_per_scale=30'
} >"$OUTPUT_DIR/manifest"
cat "$OUTPUT_DIR/result"
print -- "CJGUI_VECTOR_SCALE_VERIFY passed=true manifest=$OUTPUT_DIR/manifest"
