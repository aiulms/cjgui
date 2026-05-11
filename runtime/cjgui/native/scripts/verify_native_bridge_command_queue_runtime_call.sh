#!/usr/bin/env zsh
set -euo pipefail
# 中文维护注释：
# 本脚本验证 command queue runtime-adjacent FFI call path 与 runtime owner 存在。
# stop-line：临时仓颉包只调用 queue create / classify / destroy，不调用
# command buffer first slice 已允许；不 commit，不 present，不提交 GPU work，不执行 render。
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NATIVE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PACKAGE_DIR="$(cd "$NATIVE_DIR/.." && pwd)"
CJPM_TOML="$PACKAGE_DIR/cjpm.toml"
HEADER_FILE="$NATIVE_DIR/cjgui_native_bridge.h"
SOURCE_FILE="$NATIVE_DIR/cjgui_native_bridge.m"
RUNTIME_OWNER="$PACKAGE_DIR/src/runtime_renderer_command_queue_runtime_call.cj"
OUTPUT_DIR="$(mktemp -d /tmp/cjgui-native-bridge-command-queue-runtime-call-XXXXXX)"
NATIVE_BUILD_DIR="$OUTPUT_DIR/native-build"
PROBE_PACKAGE_DIR="$OUTPUT_DIR/command-queue-runtime-call-probe"
OBJECT_FILE="$NATIVE_BUILD_DIR/cjgui_native_bridge.o"
STATIC_LIB="$NATIVE_BUILD_DIR/libcjgui_native_bridge_command_queue_runtime_call_probe.a"
KNOWN_GOOD_SDK="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
CANGJIE_RUNTIME_LIB_DIR="/Users/jiangxuanyang/cangjie-toolchains/cangjie/runtime/lib/darwin_aarch64_cjnative"
cleanup() {
  rm -rf "$OUTPUT_DIR"
}
trap cleanup EXIT
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "cjgui command queue runtime call probe: macOS is required" >&2
  exit 2
fi
if [[ ! -f "$CJPM_TOML" || ! -f "$HEADER_FILE" || ! -f "$SOURCE_FILE" ]]; then
  echo "cjgui command queue runtime call probe: missing package/native files" >&2
  exit 3
fi
if [[ ! -f "$RUNTIME_OWNER" ]]; then
  echo "cjgui command queue runtime call probe: missing runtime owner" >&2
  exit 4
fi
if ! grep -F "CjguiInternalRendererNoCommandQueueRuntimeCallReadiness" "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: runtime endpoint missing" >&2
  exit 5
fi
if grep -E '^\s*\[ffi\.c\]' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: runtime cjpm.toml must stay unwired" >&2
  exit 6
fi
if grep -E 'cjgui_native_bridge|native/cjgui_native_bridge|link-option|compile-option' "$CJPM_TOML" >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: runtime cjpm.toml must not wire native bridge" >&2
  exit 7
fi
for symbol in \
  "cjgui_native_bridge_metal_default_device_create" \
  "cjgui_native_bridge_metal_device_destroy" \
  "cjgui_native_bridge_metal_device_table_occupied_count" \
  "cjgui_native_bridge_command_queue_create" \
  "cjgui_native_bridge_command_queue_destroy" \
  "cjgui_native_bridge_command_queue_token_classify" \
  "cjgui_native_bridge_command_queue_table_occupied_count" \
  "cjgui_native_bridge_command_queue_double_destroy_classify" \
  "cjgui_native_bridge_command_buffer_creation_still_blocked"; do
  if ! grep -F "$symbol" "$HEADER_FILE" "$SOURCE_FILE" >/dev/null 2>&1; then
    echo "cjgui command queue runtime call probe: missing callable $symbol" >&2
    exit 8
  fi
done
if grep -E 'MTLRenderCommandEncoder|renderCommandEncoder|commit]|presentDrawable|present]' "$SOURCE_FILE" >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: forbidden command buffer / submission path found" >&2
  exit 9
fi
if grep -E '^[[:space:]]*public[[:space:]]+(func|struct|class|enum|interface)' "$RUNTIME_OWNER" >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: runtime owner must stay internal" >&2
  exit 10
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  if [[ -f "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh" ]]; then
    export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH:-}"
    source "/Users/jiangxuanyang/cangjie-toolchains/cangjie/envsetup.sh"
  fi
fi
if ! command -v cjpm >/dev/null 2>&1 || ! command -v cjc >/dev/null 2>&1; then
  echo "cjgui command queue runtime call probe: cjpm/cjc not found" >&2
  exit 11
fi
CLANG_BIN="$(command -v clang || true)"
if command -v xcrun >/dev/null 2>&1; then
  CLANG_BIN="$(xcrun --sdk macosx --find clang 2>/dev/null || printf '%s' "$CLANG_BIN")"
fi
if [[ -z "${CLANG_BIN:-}" ]]; then
  echo "cjgui command queue runtime call probe: clang not found" >&2
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
  echo "cjgui command queue runtime call probe: SDKROOT not found" >&2
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
cat > "$PROBE_PACKAGE_DIR/cjpm.toml" <<CJGUI_COMMAND_QUEUE_RUNTIME_CALL_TOML
[package]
  cjc-version = "1.1.0"
  name = "cjgui_native_bridge_command_queue_runtime_call_probe"
  version = "0.0.0"
  output-type = "executable"
  src-dir = "src"
  compile-option = "--sysroot $CJ_GUI_SDKROOT"
  link-option = "-L $NATIVE_BUILD_DIR -lcjgui_native_bridge_command_queue_runtime_call_probe -framework AppKit -framework QuartzCore -framework Metal -lobjc"
CJGUI_COMMAND_QUEUE_RUNTIME_CALL_TOML
cat > "$PROBE_PACKAGE_DIR/src/main.cj" <<'CJGUI_COMMAND_QUEUE_RUNTIME_CALL_MAIN'
package cjgui_native_bridge_command_queue_runtime_call_probe
foreign func cjgui_native_bridge_metal_default_device_create(
    outToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_metal_device_destroy(token: UInt64): Int32
foreign func cjgui_native_bridge_metal_device_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_command_queue_create(
    deviceToken: UInt64,
    outQueueToken: CPointer<UInt64>
): Int32
foreign func cjgui_native_bridge_command_queue_destroy(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_queue_token_classify(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_queue_table_occupied_count(): UInt32
foreign func cjgui_native_bridge_command_queue_double_destroy_classify(
    queueToken: UInt64
): Int32
foreign func cjgui_native_bridge_command_buffer_creation_still_blocked(): Int32
main(): Int64 {
    let deviceCountBefore = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let queueCountBefore = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    var deviceToken = UInt64(0)
    var queueToken = UInt64(0)
    let deviceCreateStatus = unsafe {
        cjgui_native_bridge_metal_default_device_create(inout deviceToken)
    }
    let queueCreateStatus = unsafe {
        cjgui_native_bridge_command_queue_create(
            deviceToken,
            inout queueToken
        )
    }
    let queueClass = unsafe {
        cjgui_native_bridge_command_queue_token_classify(queueToken)
    }
    let queueCountAfterCreate = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let commandBufferStillBlocked = unsafe {
        cjgui_native_bridge_command_buffer_creation_still_blocked()
    }
    let queueDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let queueCountAfterDestroy = unsafe {
        cjgui_native_bridge_command_queue_table_occupied_count()
    }
    let destroyedClass = unsafe {
        cjgui_native_bridge_command_queue_token_classify(queueToken)
    }
    let doubleDestroyStatus = unsafe {
        cjgui_native_bridge_command_queue_destroy(queueToken)
    }
    let doubleDestroyClass = unsafe {
        cjgui_native_bridge_command_queue_double_destroy_classify(queueToken)
    }
    let deviceDestroyStatus = unsafe {
        cjgui_native_bridge_metal_device_destroy(deviceToken)
    }
    let deviceCountAfterCleanup = unsafe {
        cjgui_native_bridge_metal_device_table_occupied_count()
    }
    let success =
        deviceCreateStatus == Int32(0) &&
        queueCreateStatus == Int32(0) &&
        queueToken != UInt64(0) &&
        queueToken < UInt64(4294967296) &&
        queueClass == Int32(160) &&
        queueCountAfterCreate == queueCountBefore + UInt32(1) &&
        commandBufferStillBlocked == Int32(-169) &&
        queueDestroyStatus == Int32(0) &&
        queueCountAfterDestroy == queueCountBefore &&
        destroyedClass == Int32(-163) &&
        doubleDestroyStatus == Int32(-166) &&
        doubleDestroyClass == Int32(-166) &&
        deviceDestroyStatus == Int32(0) &&
        deviceCountAfterCleanup == deviceCountBefore
    println("cjgui command queue runtime call probe: device_create=${deviceCreateStatus}")
    println("cjgui command queue runtime call probe: queue_create=${queueCreateStatus}")
    println("cjgui command queue runtime call probe: queue_class=${queueClass}")
    println("cjgui command queue runtime call probe: command_buffer_still_blocked=${commandBufferStillBlocked}")
    println("cjgui command queue runtime call probe: queue_destroy=${queueDestroyStatus}")
    println("cjgui command queue runtime call probe: destroyed_class=${destroyedClass}")
    println("cjgui command queue runtime call probe: double_destroy=${doubleDestroyStatus}")
    println("cjgui command queue runtime call probe: token_persisted=false")
    println("cjgui command queue runtime call probe: command_buffer_created=false")
    println("cjgui command queue runtime call probe: gpu_work_submitted=false")
    println("cjgui command queue runtime call probe: render_executed=false")
    println("cjgui command queue runtime call probe: success=${success}")
    return if (success) { 0 } else { 1 }
}
CJGUI_COMMAND_QUEUE_RUNTIME_CALL_MAIN
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
  echo "cjgui command queue runtime call probe: runtime cjpm.toml changed" >&2
  exit 14
fi
echo "cjgui command queue runtime call probe: passed"
