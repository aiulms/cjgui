#!/usr/bin/env zsh

# Reproducible normal-application acceptance: a real descriptor-gated public
# UDS client batches screen-off A document rows while B receives normal AppKit
# text input in the same Cangjie application turn loop.
set -euo pipefail

SCRIPT_DIR="${0:A:h}"
RUNTIME_DIR="${SCRIPT_DIR}/../.."
OUTPUT_DIR="${1:-/private/tmp/cjgui-complex-scene-application-mixed}"
SDKROOT_PATH="${CJ_GUI_SDKROOT:-${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk}}"
TOOLCHAIN_ENV="/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
PROBE_SOURCE="$RUNTIME_DIR/probe/complex_scene_application_mixed_probe.cj"
CLIENT_SOURCE="$SCRIPT_DIR/complex_scene_application_mixed_client.py"
APP_BINARY="$OUTPUT_DIR/complex_scene_application_mixed_probe"
APP_LOG="$OUTPUT_DIR/application.log"
CLIENT_LOG="$OUTPUT_DIR/public-client.log"
MANIFEST="$OUTPUT_DIR/manifest"
NATIVE_DIR="$OUTPUT_DIR/native"

[[ -d "$SDKROOT_PATH" ]] || { print -u2 -- "missing SDK: $SDKROOT_PATH"; exit 2; }
[[ -r "$TOOLCHAIN_ENV" && -r "$PROBE_SOURCE" && -r "$CLIENT_SOURCE" ]] || {
  print -u2 -- "complex mixed probe inputs are missing"
  exit 2
}
mkdir -p "$NATIVE_DIR"

set +u
source "$TOOLCHAIN_ENV"
set -u
export SDKROOT="$SDKROOT_PATH"
export CJ_GUI_SDKROOT="$SDKROOT_PATH"
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"

print -- "probe_source=$PROBE_SOURCE" > "$MANIFEST"
print -- "client_source=$CLIENT_SOURCE" >> "$MANIFEST"
print -- "image_fixture=$RUNTIME_DIR/resources/composable-beacon.png" >> "$MANIFEST"
print -- "image_fixture_sha256=$(shasum -a 256 "$RUNTIME_DIR/resources/composable-beacon.png" | awk '{print $1}')" >> "$MANIFEST"
print -- "build_parameters=CJGUI_INTERNAL_TESTING;sysroot=$SDKROOT_PATH;macosx-version-min=12.0;argument=--complex-mixed" >> "$MANIFEST"
for source_file in "$PROBE_SOURCE" "$CLIENT_SOURCE" "$RUNTIME_DIR/src/runtime_renderer_session.cj" "$RUNTIME_DIR/src/composable_ui.cj" "$RUNTIME_DIR/src/composable_ui_window.cj" "$RUNTIME_DIR/src/macos_application_host.cj" "$RUNTIME_DIR/native/cjgui_internal_renderer.m" "$RUNTIME_DIR/native/cjgui_native_bridge.m"; do
  print -- "source_sha256[$source_file]=$(shasum -a 256 "$source_file" | awk '{print $1}')" >> "$MANIFEST"
done

(
  cd "$RUNTIME_DIR/shared_operation_core"
  cjpm build --skip-script
)

clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -DCJGUI_INTERNAL_TESTING -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_internal_renderer.m" -o "$NATIVE_DIR/cjgui_internal_renderer.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_native_bridge.m" -o "$NATIVE_DIR/cjgui_native_bridge.o"
ar rcs "$NATIVE_DIR/libcjgui_complex_scene_application_mixed.a" \
  "$NATIVE_DIR/cjgui_internal_renderer.o" "$NATIVE_DIR/cjgui_native_bridge.o"

cjc --sysroot "$SDKROOT_PATH" \
  --import-path "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$PROBE_SOURCE" \
  -L "$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core" \
  -lcjgui_shared_operation_core -L "$NATIVE_DIR" -lcjgui_complex_scene_application_mixed \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$APP_BINARY"
print -- "binary=$APP_BINARY" >> "$MANIFEST"
print -- "binary_sha256=$(shasum -a 256 "$APP_BINARY" | awk '{print $1}')" >> "$MANIFEST"
print -- "binary_size=$(stat -f '%z' "$APP_BINARY")" >> "$MANIFEST"

CJGUI_COMPLEX_MIXED_IMAGE_PATH="$RUNTIME_DIR/resources/composable-beacon.png" "$APP_BINARY" --complex-mixed > "$APP_LOG" 2>&1 &
APP_PID=$!
cleanup() {
  if kill -0 "$APP_PID" 2>/dev/null; then
    kill "$APP_PID" 2>/dev/null || true
    wait "$APP_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

descriptor=""
primary_target=""
secondary_target=""
for (( attempt = 1; attempt <= 300; attempt++ )); do
  descriptor="$(sed -n 's/^CJGUI_COMPLEX_MIXED_READY DESCRIPTOR_PATH //p' "$APP_LOG" | tail -n 1)"
  primary_target="$(sed -n 's/^CJGUI_COMPLEX_MIXED_READY PRIMARY_TARGET //p' "$APP_LOG" | tail -n 1)"
  secondary_target="$(sed -n 's/^CJGUI_COMPLEX_MIXED_READY SECONDARY_TARGET //p' "$APP_LOG" | tail -n 1)"
  if [[ -n "$descriptor" && -n "$primary_target" && -n "$secondary_target" ]]; then
    break
  fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    print -u2 -- "normal application exited before issuing descriptor"
    exit 1
  fi
  sleep 0.05
done
[[ -n "$descriptor" && -n "$primary_target" && -n "$secondary_target" ]] || {
  print -u2 -- "normal application did not issue descriptor and both window targets"
  exit 1
}
print -- "descriptor=$descriptor" >> "$MANIFEST"
print -- "primary_target=$primary_target" >> "$MANIFEST"
print -- "secondary_target=$secondary_target" >> "$MANIFEST"

python3 "$CLIENT_SOURCE" "$descriptor" "$primary_target" "$secondary_target" > "$CLIENT_LOG" 2>&1

for (( attempt = 1; attempt <= 120; attempt++ )); do
  if rg -q '^CJGUI_COMPLEX_MIXED_READY_FOR_FINAL_READS ' "$APP_LOG"; then
    break
  fi
  if ! kill -0 "$APP_PID" 2>/dev/null; then
    print -u2 -- "normal application exited before final public readback window"
    exit 1
  fi
  sleep 0.025
done
rg -q '^CJGUI_COMPLEX_MIXED_READY_FOR_FINAL_READS primary_version=30 secondary_version=30 ' "$APP_LOG"

python3 - "$CLIENT_SOURCE" "$descriptor" "$primary_target" "$secondary_target" >> "$CLIENT_LOG" 2>&1 <<'PY'
import importlib.util
import sys

source, descriptor, primary_target, secondary_target = sys.argv[1:]
spec = importlib.util.spec_from_file_location("complex_mixed_client", source)
module = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(module)
operation = module.SharedOperationClient.from_descriptor(descriptor)
targets = module.target_set(operation.get_window_targets())
module.require(targets == {primary_target, secondary_target}, "final window target set changed")
primary = module.full_document(operation, module.PRIMARY, 30)
secondary = module.full_document(operation, module.SECONDARY, 30)
module.require("batch-30-screen-off-63" in primary, "primary final screen-off batch is absent")
module.require(secondary == "B native input after A batch 30", "secondary native input readback mismatched")
primary_state = module.check_targeted_window_state(operation, primary_target, targets)
secondary_state = module.check_targeted_window_state(operation, secondary_target, targets)
print("CJGUI_COMPLEX_MIXED_PUBLIC_READBACK", {"primary_bytes": len(primary.encode()), "secondary": secondary, "primary_state": primary_state, "secondary_state": secondary_state})
PY

wait "$APP_PID"
trap - EXIT
rg -c '^CJGUI_COMPLEX_MIXED_SAMPLE sample=' "$APP_LOG" | grep -qx '30'
rg -q '^CJGUI_COMPLEX_MIXED_IMAGE_QUEUED requests=16 pending_peak=16 launches=0$' "$APP_LOG"
rg -q '^CJGUI_COMPLEX_MIXED_RESULT passed=true primary_version=30 secondary_version=30 native_input_requests=30 dynamic_structure=true dynamic_insertion=true .*image_gate_released=true image_launches=16 image_peak_inflight=[1-4] image_peak_pending=16$' "$APP_LOG"
rg -q '^CJGUI_COMPLEX_MIXED_RECLAIMED sessions_zero=true$' "$APP_LOG"
rg -q '^CJGUI_COMPLEX_MIXED_PUBLIC_BATCHES ' "$CLIENT_LOG"
rg -q '^CJGUI_COMPLEX_MIXED_PUBLIC_READBACK ' "$CLIENT_LOG"
print -- "application_log=$APP_LOG" >> "$MANIFEST"
print -- "client_log=$CLIENT_LOG" >> "$MANIFEST"
print -- "application_log_sha256=$(shasum -a 256 "$APP_LOG" | awk '{print $1}')" >> "$MANIFEST"
print -- "client_log_sha256=$(shasum -a 256 "$CLIENT_LOG" | awk '{print $1}')" >> "$MANIFEST"
print -- "samples=30" >> "$MANIFEST"
print -- "result=passed" >> "$MANIFEST"
print -- "CJGUI_COMPLEX_MIXED_MANIFEST $MANIFEST"
print -- "CJGUI_COMPLEX_MIXED_APPLICATION_LOG $APP_LOG"
print -- "CJGUI_COMPLEX_MIXED_CLIENT_LOG $CLIENT_LOG"
