#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 shader library/function runtime-adjacent FFI call path 与 runtime owner。
# stop-line：临时仓颉包只调用 device -> library -> function lookup/classify/destroy；
# 上游 shader runtime 调用路径不创建 encoder，不 draw，不 commit，不 present，
# 不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
PLANNING_OWNER="$PACKAGE_DIR/src/runtime_renderer_shader_library_no_draw_planning.cj"
SOURCE_OWNER="$PACKAGE_DIR/src/runtime_renderer_shader_source_contract.cj"
LIBRARY_OWNER="$PACKAGE_DIR/src/runtime_renderer_shader_library_create_destroy.cj"
FUNCTION_OWNER="$PACKAGE_DIR/src/runtime_renderer_shader_function_lookup.cj"
RUNTIME_OWNER="$PACKAGE_DIR/src/runtime_renderer_shader_library_runtime_call.cj"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-shader-runtime-call-XXXXXX)"
NATIVE_BUILD_DIR="$OUTPUT_DIR/native-build"
PROBE_PACKAGE_DIR="$OUTPUT_DIR/shader-runtime-call-probe"
OBJECT_FILE="$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
STATIC_LIB="$NATIVE_BUILD_DIR/libcjgui_native_bridge_shader_runtime_call_probe.a"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
cleanup() {
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui shader runtime call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$CJPM_TOML" || ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui shader runtime call probe: missing package/native files" >&2
  exit 3
fi
for owner in "$PLANNING_OWNER" "$SOURCE_OWNER" "$LIBRARY_OWNER" "$FUNCTION_OWNER" "$RUNTIME_OWNER"; do
  if [[ ! -f "$owner" ]]; then
    echo "cjgui shader runtime call probe: missing runtime owner $owner" >&2
    exit 4
  fi
done
for owner_symbol in \
  "CjguiInternalRendererNoShaderLibraryNoDrawPlanningReadiness" \
  "CjguiInternalRendererNoShaderSourceContractReadiness" \
  "CjguiInternalRendererNoShaderLibraryCreateDestroyReadiness" \
  "CjguiInternalRendererNoShaderFunctionLookupReadiness" \
  "CjguiInternalRendererNoShaderLibraryRuntimeCallReadiness" \
  "cjguiInternalExecuteDefaultRendererShaderLibraryRuntimeCallDraft"; do
  if ! grep -F "$owner_symbol" "$PLANNING_OWNER" "$SOURCE_OWNER" "$LIBRARY_OWNER" "$FUNCTION_OWNER" "$RUNTIME_OWNER" >/dev/null 2>&1; then
    echo "cjgui shader runtime call probe: missing owner symbol $owner_symbol" >&2
    exit 5
  fi
done
if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui shader runtime call probe: runtime cjpm.toml must stay unwired" >&2
  exit 6
fi
if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui shader runtime call probe: runtime cjpm.toml must not wire native bridge" >&2
  exit 7
fi
if grep -Eq 'renderCommandEncoder|setRenderPipelineState|drawPrimitives|drawIndexedPrimitives|newBuffer|commit]|presentDrawable|present]|dispatchThreadgroups' "$SOURCE_FILE"; then
  echo "cjgui shader runtime call probe: forbidden encoder / submit path found" >&2
  exit 8
fi
if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|interface)' "$PLANNING_OWNER" "$SOURCE_OWNER" "$LIBRARY_OWNER" "$FUNCTION_OWNER" "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui shader runtime call probe: runtime owner must stay internal" >&2
  exit 9
fi
for symbol in \
  "cjgui_native_bridge_shader_source_contract_available" \
  "cjgui_native_bridge_shader_library_create" \
  "cjgui_native_bridge_shader_library_destroy" \
  "cjgui_native_bridge_shader_library_token_classify" \
  "cjgui_native_bridge_shader_function_lookup_vertex" \
  "cjgui_native_bridge_shader_function_lookup_fragment" \
  "cjgui_native_bridge_shader_function_destroy" \
  "cjgui_native_bridge_shader_function_token_classify" \
  "cjgui_native_bridge_shader_function_double_destroy_classify" \
  "cjgui_native_bridge_shader_pipeline_state_creation_still_blocked" \
  "cjgui_native_bridge_shader_encoder_binding_still_blocked" \
  "cjgui_native_bridge_shader_draw_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui shader runtime call probe: missing callable $symbol" >&2
    exit 10
  fi
done
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui shader runtime call probe: cjpm/cjc not found" >&2
  exit 11
fi
CLANG_BIN="$(command -v clang || true)"
if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || printf '%s' "$CLANG_BIN")"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui shader runtime call probe: clang not found" >&2
  exit 12
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" && -d "$KNOWN_GOOD_SDK" ]]; then
  CJ_GUI_SDKROOT="$KNOWN_GOOD_SDK"
elif [[ -z "${CJ_GUI_SDKROOT:-}" && -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  CJ_GUI_SDKROOT="$SDKROOT"
elif [[ -z "${CJ_GUI_SDKROOT:-}" ]] && command -v xcrun >/dev/null 2>&1; then
  CJ_GUI_SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "${CJ_GUI_SDKROOT:-}" || ! -d "$CJ_GUI_SDKROOT" ]]; then
  echo "cjgui shader runtime call probe: SDKROOT not found" >&2
  exit 13
fi
RUNTIME_CJPM_HASH_BEFORE="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
mkdir -p "$NATIVE_BUILD_DIR" "$PROBE_PACKAGE_DIR/src"
"$CLANG_BIN" \
  -fobjc-arc \
  -fno-objc-msgsend-selector-stubs \
  -fmodules \
  -isysroot "$CJ_GUI_SDKROOT" \
  -mmacosx-version-min=12.0 \
  -c "$SOURCE_FILE" \
  -o "$OBJECT_FILE"
ar rcs "$STATIC_LIB" "$OBJECT_FILE"
cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_SHADER_RUNTIME_CALL_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_native_bridge_shader_runtime_call_probe"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
  link-option = "-L $NATIVE_BUILD_DIR -lcjgui_native_bridge_shader_runtime_call_probe -framework AppKit -framework QuartzCore -framework Metal -lobjc"
CJGUI_SHADER_RUNTIME_CALL_TOML
cat > "$PROBE_PACKAGE_DIR/src/main.cj" <<'CJGUI_SHADER_RUNTIME_CALL_MAIN'
package cjgui_native_bridge_shader_runtime_call_probe
foreign func cjgui_native_bridge_metal_default_device_available(): Int32
foreign func cjgui_native_bridge_metal_default_device_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_metal_device_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_shader_library_create(
    deviceToken: UInt64,
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_library_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_shader_library_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_lookup_vertex(
    libraryToken: UInt64,
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_function_lookup_fragment(
    libraryToken: UInt64,
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_shader_function_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_shader_function_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_shader_function_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_shader_pipeline_state_creation_still_blocked():
    Int32
foreign func cjgui_native_bridge_shader_encoder_binding_still_blocked(): Int32
foreign func cjgui_native_bridge_shader_draw_still_blocked(): Int32
main(): Int64 {
    let availability = unsafe {
        cjgui_native_bridge_metal_default_device_available()
    }
    if (availability <= Int32(0)) {
        println("cjgui shader runtime call probe: skipped_no_device")
        return 0
    }
    let functionCountBefore = unsafe {
        cjgui_native_bridge_shader_function_table_occupied_count()
    }
    var deviceToken = UInt64(0)
    let deviceCreate = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    var libraryToken = UInt64(0)
    let libraryCreate = unsafe {
        cjgui_native_bridge_shader_library_create(deviceToken, inout libraryToken)
    }
    var vertexToken = UInt64(0)
    let vertexLookup = unsafe {
        cjgui_native_bridge_shader_function_lookup_vertex(
            libraryToken,
            inout vertexToken
        )
    }
    var fragmentToken = UInt64(0)
    let fragmentLookup = unsafe {
        cjgui_native_bridge_shader_function_lookup_fragment(
            libraryToken,
            inout fragmentToken
        )
    }
    let vertexClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(vertexToken)
    }
    let fragmentClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(fragmentToken)
    }
    let libraryClass = unsafe {
        cjgui_native_bridge_shader_library_token_classify(libraryToken)
    }
    let pipelineStateBlocked = unsafe {
        cjgui_native_bridge_shader_pipeline_state_creation_still_blocked()
    }
    let encoderBlocked = unsafe {
        cjgui_native_bridge_shader_encoder_binding_still_blocked()
    }
    let drawBlocked = unsafe {
        cjgui_native_bridge_shader_draw_still_blocked()
    }
    let vertexDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let fragmentDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(fragmentToken)
    }
    let functionCountAfterCleanup = unsafe {
        cjgui_native_bridge_shader_function_table_occupied_count()
    }
    let vertexDestroyedClass = unsafe {
        cjgui_native_bridge_shader_function_token_classify(vertexToken)
    }
    let vertexDoubleDestroy = unsafe {
        cjgui_native_bridge_shader_function_destroy(vertexToken)
    }
    let vertexDoubleDestroyClass = unsafe {
        cjgui_native_bridge_shader_function_double_destroy_classify(vertexToken)
    }
    let libraryDestroy = unsafe {
        cjgui_native_bridge_shader_library_destroy(libraryToken)
    }
    let deviceDestroy = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let success =
        deviceCreate == Int32(0) &&
        libraryCreate == Int32(0) &&
        vertexLookup == Int32(0) &&
        fragmentLookup == Int32(0) &&
        vertexClass == Int32(242) &&
        fragmentClass == Int32(243) &&
        libraryClass == Int32(241) &&
        vertexToken != UInt64(0) &&
        fragmentToken != UInt64(0) &&
        vertexToken != fragmentToken &&
        pipelineStateBlocked == Int32(-252) &&
        encoderBlocked == Int32(-253) &&
        drawBlocked == Int32(-254) &&
        vertexDestroy == Int32(0) &&
        fragmentDestroy == Int32(0) &&
        functionCountAfterCleanup == functionCountBefore &&
        vertexDestroyedClass == Int32(-263) &&
        vertexDoubleDestroy == Int32(-265) &&
        vertexDoubleDestroyClass == Int32(-265) &&
        libraryDestroy == Int32(0) &&
        deviceDestroy == Int32(0)
    println("cjgui shader runtime call probe: library_create=${libraryCreate}")
    println("cjgui shader runtime call probe: vertex_lookup=${vertexLookup}")
    println("cjgui shader runtime call probe: fragment_lookup=${fragmentLookup}")
    println("cjgui shader runtime call probe: vertex_class=${vertexClass}")
    println("cjgui shader runtime call probe: fragment_class=${fragmentClass}")
    println("cjgui shader runtime call probe: token_persisted=false")
    println("cjgui shader runtime call probe: pipeline_state_created=false")
    println("cjgui shader runtime call probe: encoder_created=false")
    println("cjgui shader runtime call probe: draw_called=false")
    println("cjgui shader runtime call probe: commit_called=false")
    println("cjgui shader runtime call probe: present_called=false")
    println("cjgui shader runtime call probe: gpu_work_submitted=false")
    println("cjgui shader runtime call probe: render_executed=false")
    println("cjgui shader runtime call probe: success=${success}")
    return if (success) { 0 } else { 1 }
}
CJGUI_SHADER_RUNTIME_CALL_MAIN
(
  cd "$PROBE_PACKAGE_DIR"
  cjpm build --target-dir "$OUTPUT_DIR/cjpm-target" --skip-script
  if [[ -d "$CANGJIE_RUNTIME_LIB_DIR" ]]; then
    export DYLD_LIBRARY_PATH="$CANGJIE_RUNTIME_LIB_DIR:${DYLD_LIBRARY_PATH:-}"
  fi
  "$OUTPUT_DIR/cjpm-target/release/bin/main"
)
RUNTIME_CJPM_HASH_AFTER="$(shasum -a 256 "$CJPM_TOML" | awk '{print $1}')"
if [[ "$RUNTIME_CJPM_HASH_BEFORE" != "$RUNTIME_CJPM_HASH_AFTER" ]]; then
  echo "cjgui shader runtime call probe: runtime cjpm.toml changed" >&2
  exit 14
fi
echo "cjgui shader runtime call probe: passed"
