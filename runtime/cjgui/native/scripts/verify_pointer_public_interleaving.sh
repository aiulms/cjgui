#!/usr/bin/env zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$(cd "$(dirname "$0")" && pwd)/lib_cjgui_source_set.sh"
typeset -a CJGUI_FRAMEWORK_SOURCE_PATHS
CJGUI_FRAMEWORK_SOURCE_PATHS=("${(@f)$(cjgui_framework_source_paths "$RUNTIME_DIR" false)}")
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
OUTPUT_DIR="${CJGUI_POINTER_PUBLIC_INTERLEAVE_TMPDIR:-/private/tmp/cjgui-pointer-public-interleave}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

set +u
source "/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3/envsetup.sh"
set -u
mkdir -p "$OUTPUT_DIR/native"

if [[ "${1:-}" != "--run-only" ]]; then
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
ar rcs "$OUTPUT_DIR/native/libcjgui_pointer_public_interleave.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o"
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_macos_application_launcher.m" \
  -o "$OUTPUT_DIR/native/cjgui_macos_application_launcher.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_pointer_public_interleave_host.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o" \
  "$OUTPUT_DIR/native/cjgui_macos_application_launcher.o"

SHARED_CORE="$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core"
cjc --sysroot "$SDKROOT_PATH" --import-path "$SHARED_CORE" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/pointer_public_interleaving_probe.cj" \
  -L "$SHARED_CORE" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_pointer_public_interleave \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/pointer_public_interleaving_probe"
cjc --sysroot "$SDKROOT_PATH" --import-path "$SHARED_CORE" \
  "${CJGUI_FRAMEWORK_SOURCE_PATHS[@]}" \
  "$RUNTIME_DIR/probe/pointer_public_interleaving_probe.cj" \
  -L "$SHARED_CORE" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_pointer_public_interleave_host \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/pointer_public_interleaving_host_probe"

if [[ "${1:-}" == "--build-only" ]]; then
  print -r -- "pointer public interleave verifier: BUILD_ONLY output=$OUTPUT_DIR"
  exit 0
fi
fi

[[ -x "$OUTPUT_DIR/pointer_public_interleaving_probe" ]] || {
  print -u2 -- "pointer public interleave verifier: missing built probe"
  exit 1
}

UNRELATED_ACK="$OUTPUT_DIR/unrelated.ack"
SAME_ACK="$OUTPUT_DIR/same.ack"
MOTION_ACK="$OUTPUT_DIR/motion.ack"
LOG="$OUTPUT_DIR/probe.log"
CALL_LOG="$OUTPUT_DIR/public-calls.log"
rm -f "$UNRELATED_ACK" "$SAME_ACK" "$MOTION_ACK" "$LOG" "$CALL_LOG"
export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
"$OUTPUT_DIR/pointer_public_interleaving_probe" --unrelated-ack "$UNRELATED_ACK" \
  --same-ack "$SAME_ACK" --motion-ack "$MOTION_ACK" >"$LOG" 2>&1 &
PROBE_PID=$!

wait_for_line() {
  local needle="$1"
  local attempts=0
  while (( attempts < 160 )); do
    if rg -q "$needle" "$LOG" 2>/dev/null; then
      return 0
    fi
    if ! kill -0 "$PROBE_PID" 2>/dev/null; then
      wait "$PROBE_PID"
      return 1
    fi
    sleep 0.05
    (( attempts += 1 ))
  done
  print -u2 -- "pointer public interleave verifier: timeout waiting for $needle"
  return 1
}

wait_for_line '^CJGUI_POINTER_PUBLIC_INTERLEAVE_READY DESCRIPTOR_PATH '
DESCRIPTOR_PATH="$(rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_READY DESCRIPTOR_PATH ' "$LOG" | tail -n 1 | awk '{print $3}')"

invoke_current() {
  local target="$1"
  local value="$2"
  local ack_path="$3"
  local label="$4"
  local version
  version="$(python3 "$CLIENT" "$DESCRIPTOR_PATH" get --target "$target" | awk '$1 == "VERSION" { print $2; exit }')"
  if [[ -z "$version" ]]; then
    print -u2 -- "pointer public interleave verifier: no public version for $label"
    return 1
  fi
  print -r -- "CJGUI_POINTER_PUBLIC_INTERLEAVE_CALL $label expected_version=$version target=$target value=$value" >>"$CALL_LOG"
  python3 "$CLIENT" "$DESCRIPTOR_PATH" invoke "$version" SET_PREVIEW_LIMIT --target "$target" --arg "value=INTEGER:$value" >>"$CALL_LOG"
  touch "$ack_path"
}

wait_for_line '^CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE UNRELATED_READY '
invoke_current 7102 256 "$UNRELATED_ACK" UNRELATED
wait_for_line '^CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE SAME_READY '
invoke_current 7101 416 "$SAME_ACK" SAME
wait_for_line '^CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE MOTION_READY '
set +e
python3 - "$RUNTIME_DIR/shared_operation_core" "$DESCRIPTOR_PATH" "$MOTION_ACK" >>"$CALL_LOG" <<'PY'
import pathlib
import sys
import time

sys.path.insert(0, sys.argv[1])
from client import SharedOperationArgument, SharedOperationClient

client = SharedOperationClient.from_descriptor(sys.argv[2])
before = client.get_context()
version = before.integer("VERSION")
started = time.monotonic_ns()
result = client.invoke(version, "SET_PREVIEW_LIMIT", [7102],
                       [SharedOperationArgument.integer("value", 384)])
invoke_ns = time.monotonic_ns() - started
if result.kind != "RESULT" or not result.boolean("APPLIED"):
    raise SystemExit(f"motion public request rejected: {result.raw!r}")
after = client.get_context()
if after.integer("VERSION") != version + 1:
    raise SystemExit(f"motion public owner version changed unexpectedly: {after.raw!r}")
print(f"CJGUI_POINTER_PUBLIC_INTERLEAVE_CALL MOTION expected_version={version} "
      f"target=7102 value=384 invoke_ns={invoke_ns} owner_after={after.integer('VERSION')}",
      flush=True)
pathlib.Path(sys.argv[3]).touch()
PY
motion_client_exit=$?
if (( motion_client_exit != 0 )); then
  wait "$PROBE_PID"
  probe_exit=$?
  print -u2 -- "pointer public interleave verifier: motion client exit=$motion_client_exit probe exit=$probe_exit"
  exit 1
fi
set -e
wait "$PROBE_PID"

rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_CALL UNRELATED ' "$CALL_LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_CALL SAME ' "$CALL_LOG"
rg '^APPLIED true$' "$CALL_LOG" | wc -l | tr -d ' ' | rg '^2$'
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_CALL MOTION .*invoke_ns=[0-9]+ owner_after=[0-9]+$' "$CALL_LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE UNRELATED .*overlap=true .*acknowledgement_seen=true$' "$LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_PHASE SAME .*overlap=true .*acknowledgement_seen=true$' "$LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_RESULT UNRELATED .*owner_end=1 .*owner_cancel=0 .*b_scene_before=.* b_scene_after=.* b_value=256 passed=true$' "$LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_RESULT SAME .*owner_cancel_after=1 .*external_value=416 .*final_value=416 passed=true$' "$LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_RESULT MOTION .*external_actions=1 moving_at_public=true .*b_value=384 .*acknowledgement_seen=true passed=true$' "$LOG"
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_TRANSPORT .*accepted_high_water=1 ready_high_water=1 ' "$LOG"
WRONG_THREAD_LOG="$OUTPUT_DIR/wrong-thread.log"
"$OUTPUT_DIR/pointer_public_interleaving_host_probe" --unrelated-ack "$UNRELATED_ACK" \
  --same-ack "$SAME_ACK" --motion-ack "$MOTION_ACK" --wrong-thread >"$WRONG_THREAD_LOG" 2>&1
rg '^CJGUI_POINTER_PUBLIC_INTERLEAVE_WRONG_THREAD .*kept_after_pump=true kept_after_rejection=true .*descriptor_live=true legal_status=0 legal_pump=true .*refused_consumption=false retained_delivered=true legal_close=true passed=true$' "$WRONG_THREAD_LOG"
print -r -- "pointer public interleave verifier: PASS real_uds=1 same_scheduler_overlap=1 unrelated_owner_preserves_capture=1 same_owner_cancels_old_move_end=1 independent_b_scene=1 animated_a_public_b=1 wrong_thread_same_session_recovery=1"
