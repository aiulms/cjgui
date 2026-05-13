#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 pipeline descriptor runtime-adjacent FFI call path 与 runtime owner。
# stop-line：临时仓颉包只调用 descriptor create/config/classify/destroy；
# 不创建 pipeline state、encoder，不 draw，不 commit；shader library/function
# 已由后续 no-draw 阶段单独验证，不 present，不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
CREATE_DESTROY_OWNER="$PACKAGE_DIR/src/runtime_renderer_pipeline_descriptor_create_destroy.cj"
CONFIGURATION_OWNER="$PACKAGE_DIR/src/runtime_renderer_pipeline_descriptor_configuration.cj"
RUNTIME_OWNER="$PACKAGE_DIR/src/runtime_renderer_pipeline_descriptor_runtime_call.cj"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-pipeline-descriptor-runtime-call-XXXXXX)"
NATIVE_BUILD_DIR="$OUTPUT_DIR/native-build"
PROBE_PACKAGE_DIR="$OUTPUT_DIR/pipeline-descriptor-runtime-call-probe"
OBJECT_FILE="$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
STATIC_LIB="$NATIVE_BUILD_DIR/libcjgui_native_bridge_pipeline_descriptor_runtime_call_probe.a"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
cleanup() {
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui pipeline descriptor runtime call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$CJPM_TOML" || ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui pipeline descriptor runtime call probe: missing package/native files" >&2
  exit 3
fi
if [[ ! -f "$CREATE_DESTROY_OWNER" || ! -f "$CONFIGURATION_OWNER" || ! -f "$RUNTIME_OWNER" ]]; then
  echo "cjgui pipeline descriptor runtime call probe: missing runtime owner" >&2
  exit 4
fi
for owner_symbol in \
  "CjguiInternalRendererNoPipelineDescriptorCreateDestroyReadiness" \
  "CjguiInternalRendererNoPipelineDescriptorConfigurationReadiness" \
  "CjguiInternalRendererNoPipelineDescriptorRuntimeCallReadiness" \
  "cjguiInternalExecuteDefaultRendererPipelineDescriptorRuntimeCallDraft"; do
  if ! grep -F "$owner_symbol" "$CREATE_DESTROY_OWNER" "$CONFIGURATION_OWNER" "$RUNTIME_OWNER" >/dev/null 2>&1; then
    echo "cjgui pipeline descriptor runtime call probe: missing owner symbol $owner_symbol" >&2
    exit 5
  fi
done
if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui pipeline descriptor runtime call probe: runtime cjpm.toml must stay unwired" >&2
  exit 6
fi
if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui pipeline descriptor runtime call probe: runtime cjpm.toml must not wire native bridge" >&2
  exit 7
fi
if grep -Eq 'newRenderPipelineState|MTLRenderPipelineState|renderCommandEncoder|setRenderPipelineState|drawPrimitives|drawIndexedPrimitives|newBuffer|commit]|presentDrawable|present]|dispatchThreadgroups' "$SOURCE_FILE"; then
  echo "cjgui pipeline descriptor runtime call probe: forbidden pipeline / encoder / submit path found" >&2
  exit 8
fi
if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|interface)' "$CREATE_DESTROY_OWNER" "$CONFIGURATION_OWNER" "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui pipeline descriptor runtime call probe: runtime owner must stay internal" >&2
  exit 9
fi
for symbol in \
  "cjgui_native_bridge_pipeline_descriptor_create" \
  "cjgui_native_bridge_pipeline_descriptor_destroy" \
  "cjgui_native_bridge_pipeline_descriptor_token_classify" \
  "cjgui_native_bridge_pipeline_descriptor_double_destroy_classify" \
  "cjgui_native_bridge_pipeline_descriptor_table_occupied_count" \
  "cjgui_native_bridge_pipeline_descriptor_configure_no_draw" \
  "cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify" \
  "cjgui_native_bridge_pipeline_descriptor_sample_count_classify" \
  "cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked" \
  "cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked" \
  "cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked" \
  "cjgui_native_bridge_pipeline_descriptor_blending_still_blocked" \
  "cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked" \
  "cjgui_native_bridge_pipeline_state_creation_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui pipeline descriptor runtime call probe: missing callable $symbol" >&2
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
  echo "cjgui pipeline descriptor runtime call probe: cjpm/cjc not found" >&2
  exit 11
fi
CLANG_BIN="$(command -v clang || true)"
if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || printf '%s' "$CLANG_BIN")"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui pipeline descriptor runtime call probe: clang not found" >&2
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
  echo "cjgui pipeline descriptor runtime call probe: SDKROOT not found" >&2
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
cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_PIPELINE_DESCRIPTOR_RUNTIME_CALL_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_native_bridge_pipeline_descriptor_runtime_call_probe"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
  link-option = "-L $NATIVE_BUILD_DIR -lcjgui_native_bridge_pipeline_descriptor_runtime_call_probe -framework AppKit -framework QuartzCore -framework Metal -lobjc"
CJGUI_PIPELINE_DESCRIPTOR_RUNTIME_CALL_TOML
cat > "$PROBE_PACKAGE_DIR/src/main.cj" <<'CJGUI_PIPELINE_DESCRIPTOR_RUNTIME_CALL_MAIN'
package cjgui_native_bridge_pipeline_descriptor_runtime_call_probe
foreign func cjgui_native_bridge_pipeline_descriptor_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_destroy(token: UInt64):
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_token_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_table_occupied_count():
    UInt32
foreign func cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
    token: UInt64
): Int32
foreign func cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_blending_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked():
    Int32
foreign func cjgui_native_bridge_pipeline_state_creation_still_blocked(): Int32
main(): Int64 {
    let countBefore = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    var descriptorToken = UInt64(0)
    let createStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_create(inout descriptorToken)
    }
    let countAfterCreate = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let configureStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_configure_no_draw(
            descriptorToken
        )
    }
    let validClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_token_classify(descriptorToken)
    }
    let pixelClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_color_pixel_format_classify(
            descriptorToken
        )
    }
    let sampleClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_sample_count_classify(
            descriptorToken
        )
    }
    let pipelineStateBlocked = unsafe {
        cjgui_native_bridge_pipeline_state_creation_still_blocked()
    }
    let shaderLibraryBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_shader_library_still_blocked()
    }
    let vertexFunctionBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_vertex_function_still_blocked()
    }
    let fragmentFunctionBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_fragment_function_still_blocked()
    }
    let blendingBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_blending_still_blocked()
    }
    let encoderBindingBlocked = unsafe {
        cjgui_native_bridge_pipeline_descriptor_encoder_binding_still_blocked()
    }
    let destroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let countAfterCleanup = unsafe {
        cjgui_native_bridge_pipeline_descriptor_table_occupied_count()
    }
    let destroyedClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_token_classify(descriptorToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_pipeline_descriptor_destroy(descriptorToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_pipeline_descriptor_double_destroy_classify(
            descriptorToken
        )
    }
    let success =
        createStatus == Int32(0) &&
        descriptorToken != UInt64(0) &&
        descriptorToken < UInt64(4294967296) &&
        countAfterCreate == countBefore + UInt32(1) &&
        configureStatus == Int32(0) &&
        validClass == Int32(220) &&
        pixelClass == Int32(222) &&
        sampleClass == Int32(223) &&
        pipelineStateBlocked == Int32(-229) &&
        shaderLibraryBlocked == Int32(-230) &&
        vertexFunctionBlocked == Int32(-231) &&
        fragmentFunctionBlocked == Int32(-232) &&
        blendingBlocked == Int32(-233) &&
        encoderBindingBlocked == Int32(-234) &&
        destroyStatus == Int32(0) &&
        countAfterCleanup == countBefore &&
        destroyedClass == Int32(-223) &&
        doubleDestroyStatus == Int32(-226) &&
        doubleDestroyClass == Int32(-226)
    println("cjgui pipeline descriptor runtime call probe: create=${createStatus}")
    println("cjgui pipeline descriptor runtime call probe: configure=${configureStatus}")
    println("cjgui pipeline descriptor runtime call probe: valid_class=${validClass}")
    println("cjgui pipeline descriptor runtime call probe: pixel_class=${pixelClass}")
    println("cjgui pipeline descriptor runtime call probe: sample_class=${sampleClass}")
    println("cjgui pipeline descriptor runtime call probe: destroy=${destroyStatus}")
    println("cjgui pipeline descriptor runtime call probe: double_destroy=${doubleDestroyStatus}")
    println("cjgui pipeline descriptor runtime call probe: token_persisted=false")
    println("cjgui pipeline descriptor runtime call probe: pipeline_state_created=false")
    println("cjgui pipeline descriptor runtime call probe: shader_library_created=false")
    println("cjgui pipeline descriptor runtime call probe: encoder_created=false")
    println("cjgui pipeline descriptor runtime call probe: draw_called=false")
    println("cjgui pipeline descriptor runtime call probe: commit_called=false")
    println("cjgui pipeline descriptor runtime call probe: present_called=false")
    println("cjgui pipeline descriptor runtime call probe: gpu_work_submitted=false")
    println("cjgui pipeline descriptor runtime call probe: render_executed=false")
    println("cjgui pipeline descriptor runtime call probe: success=${success}")
    return if (success) { 0 } else { 1 }
}
CJGUI_PIPELINE_DESCRIPTOR_RUNTIME_CALL_MAIN
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
  echo "cjgui pipeline descriptor runtime call probe: runtime cjpm.toml changed" >&2
  exit 14
fi
echo "cjgui pipeline descriptor runtime call probe: passed"
