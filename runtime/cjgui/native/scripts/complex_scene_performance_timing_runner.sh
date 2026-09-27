#!/bin/zsh
set -euo pipefail

# Reproducible runner for the real Cangjie complex-scope window transaction.
# The probe emits 30 local-refresh samples for each of 16/128/480 scopes,
# plus the scope-generation semantic regression. This is not the four-node
# refresh-timing probe.
SCRIPT_DIR="${0:A:h}"
RUNTIME_DIR="${SCRIPT_DIR}/../.."
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
OUTPUT_DIR="${1:-/private/tmp/cjgui-complex-scene-scope-timing}"
MIN_SAMPLES="${2:-30}"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}}"
TOOLCHAIN_ENV="/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
PROBE_SOURCE="$RUNTIME_DIR/probe/complex_scene_scope_timing_probe.cj"
BINARY="$OUTPUT_DIR/complex_scene_scope_timing_probe"
LOG="$OUTPUT_DIR/complex_scene_scope_timing.log"
STDERR_LOG="$OUTPUT_DIR/complex_scene_scope_timing.stderr"
MANIFEST="$OUTPUT_DIR/complex_scene_timing.manifest"

[[ "$MIN_SAMPLES" == <-> ]] && (( MIN_SAMPLES >= 30 )) || { print -u2 -- "complex scope runner needs at least 30 samples"; exit 2; }
[[ -d "$SDKROOT_PATH" ]] || { print -u2 -- "missing SDK: $SDKROOT_PATH"; exit 1; }
[[ -r "$TOOLCHAIN_ENV" ]] || { print -u2 -- "missing Cangjie environment: $TOOLCHAIN_ENV"; exit 1; }
[[ -r "$PROBE_SOURCE" ]] || { print -u2 -- "missing probe: $PROBE_SOURCE"; exit 1; }
mkdir -p "$OUTPUT_DIR/native"

set +u
source "$TOOLCHAIN_ENV"
set -u
export SDKROOT="$SDKROOT_PATH"
export CJ_GUI_SDKROOT="$SDKROOT_PATH"

print -- "build_parameters=CJGUI_INTERNAL_TESTING;sysroot=$SDKROOT_PATH;macosx-version-min=12.0;probe=$PROBE_SOURCE" > "$MANIFEST"
print -- "source_probe=$PROBE_SOURCE" >> "$MANIFEST"
print -- "source_probe_sha256=$(shasum -a 256 "$PROBE_SOURCE" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_window_sha256=$(shasum -a 256 "$RUNTIME_DIR/src/composable_ui_window.cj" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_session_sha256=$(shasum -a 256 "$RUNTIME_DIR/src/runtime_renderer_session.cj" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_ui_sha256=$(shasum -a 256 "$RUNTIME_DIR/src/composable_ui.cj" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_component_instance_sha256=$(shasum -a 256 "$RUNTIME_DIR/src/composable_ui_component_instance.cj" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_renderer_sha256=$(shasum -a 256 "$RUNTIME_DIR/native/cjgui_internal_renderer.m" | awk '{print $1}')" >> "$MANIFEST"
print -- "source_native_bridge_sha256=$(shasum -a 256 "$RUNTIME_DIR/native/cjgui_native_bridge.m" | awk '{print $1}')" >> "$MANIFEST"
print -- "toolchain_env=$TOOLCHAIN_ENV" >> "$MANIFEST"
print -- "sdkroot=$SDKROOT_PATH" >> "$MANIFEST"
print -- "host=$(uname -a)" >> "$MANIFEST"

(
  cd "$RUNTIME_DIR/shared_operation_core"
  cjpm build --skip-script
)
print -- "shared_operation_core_library=$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core/libcjgui_shared_operation_core.a" >> "$MANIFEST"
print -- "shared_operation_core_library_sha256=$(shasum -a 256 "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core/libcjgui_shared_operation_core.a" | awk '{print $1}')" >> "$MANIFEST"

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$OUTPUT_DIR/native/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$OUTPUT_DIR/native/cjgui_native_bridge.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_complex_scene_scope_timing.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$PROBE_SOURCE" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core -L "$OUTPUT_DIR/native" -lcjgui_complex_scene_scope_timing \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$BINARY"

print -- "binary=$BINARY" >> "$MANIFEST"
print -- "binary_sha256=$(shasum -a 256 "$BINARY" | awk '{print $1}')" >> "$MANIFEST"
print -- "binary_size=$(stat -f '%z' "$BINARY")" >> "$MANIFEST"
print -- "required_samples=$MIN_SAMPLES" >> "$MANIFEST"
print -- "log=$LOG" >> "$MANIFEST"
print -- "stderr_log=$STDERR_LOG" >> "$MANIFEST"

RUNS=$(( (MIN_SAMPLES + 29) / 30 ))
: > "$LOG"
: > "$STDERR_LOG"
export DYLD_LIBRARY_PATH="${CANGJIE_HOME}/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
for (( run = 1; run <= RUNS; run++ )); do
    print -- "RUN_INDEX $run" >> "$LOG"
    "$BINARY" >> "$LOG" 2>> "$STDERR_LOG"
done

for scope in 16 128 480; do
    count="$(rg -c "CJGUI_COMPLEX_SCOPE_SAMPLE scopes=${scope} " "$LOG" || true)"
    (( count >= MIN_SAMPLES )) || { print -u2 -- "scope=$scope samples=$count/$MIN_SAMPLES; log=$LOG"; exit 1; }
done
regression_count="$(rg -c '^CJGUI_SCOPE_GENERATION_REGRESSION ' "$LOG" || true)"
(( regression_count == RUNS )) || { print -u2 -- "scope-generation regression markers=$regression_count/$RUNS; log=$LOG"; exit 1; }
passed_count="$(rg -c '^cjgui complex scope timing probe: passed$' "$LOG" || true)"
(( passed_count == RUNS )) || { print -u2 -- "probe pass markers=$passed_count/$RUNS; log=$LOG"; exit 1; }

print -- "log_sha256=$(shasum -a 256 "$LOG" | awk '{print $1}')" >> "$MANIFEST"
print -- "stderr_log_sha256=$(shasum -a 256 "$STDERR_LOG" | awk '{print $1}')" >> "$MANIFEST"
print -- "complex_scope_runs=$RUNS" >> "$MANIFEST"
print -- "complex_scope_samples_per_run=30" >> "$MANIFEST"
print -- "COMPLEX_SCENE_SCOPE_TIMING_BINARY $BINARY"
print -- "COMPLEX_SCENE_SCOPE_TIMING_LOG $LOG"
print -- "COMPLEX_SCENE_SCOPE_TIMING_STDERR $STDERR_LOG"
print -- "COMPLEX_SCENE_SCOPE_TIMING_MANIFEST $MANIFEST"
print -- "COMPLEX_SCENE_SCOPE_TIMING_SAMPLES $((RUNS * 30))"
print -- "COMPLEX_SCENE_SCOPE_TIMING_REGRESSION $regression_count"
