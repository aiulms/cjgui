#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
RUN_MODE="${CJGUI_INTERACTION_SCHEDULING_RUN_MODE:-full}"
if [[ "$RUN_MODE" == "latency" ]]; then
  OUTPUT_DIR="${CJGUI_INTERACTION_SCHEDULING_TMPDIR:-/private/tmp/cjgui-dual-window-latency/$(date +%Y%m%d-%H%M%S)-$$}"
else
  OUTPUT_DIR="${CJGUI_INTERACTION_SCHEDULING_TMPDIR:-/private/tmp/cjgui-interaction-scheduling-efficiency}"
fi
LATENCY_DIR="$OUTPUT_DIR"
SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path)"
SHARED_CORE="$RUNTIME_DIR/shared_operation_core/target/release/cjgui_shared_operation_core"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
PROBE_SRC="$RUNTIME_DIR/probe/interaction_scheduling_efficiency_probe.cj"
LATENCY_CLIENT_SRC="$SCRIPT_DIR/latency_public_client.py"
SHARED_CORE_LIBRARY="$SHARED_CORE/libcjgui_shared_operation_core.a"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

require_source_line() {
  local expected="$1"
  if ! rg -F -q -- "$expected" "$PROBE_SRC"; then
    print -u2 -- "interaction scheduling verifier: missing source line: $expected"
    exit 1
  fi
}

require_source_line "cjgui_internal_renderer_test_send_composable_mouse"
require_source_line "cjgui_internal_renderer_test_set_composable_present_failures"
require_source_line "CjguiSharedOperationExternalConnection"
require_source_line "refresh_compare_ns="
require_source_line "native_stage_submit_ms="
require_source_line "terminal_exact="
require_source_line "generic_split="
require_source_line "CJGUI_INTERACTION_SCHEDULING_OVERLAP_READY"
require_source_line "ArrayList<Int64>([8, 128, 960])"
require_source_line "CJGUI_INTERACTION_SCHEDULING_LATENCY_RESULT"
require_source_line "--latency-only"

if [[ "$RUN_MODE" != "full" && "$RUN_MODE" != "overlap" && "$RUN_MODE" != "latency" ]]; then
  print -u2 -- "interaction scheduling verifier: unsupported run mode: $RUN_MODE"
  exit 2
fi

mkdir -p "$OUTPUT_DIR/native" "$OUTPUT_DIR/acks"
LOG="$OUTPUT_DIR/probe.log"
CALL_LOG="$OUTPUT_DIR/public-calls.log"
LATENCY_CLIENT_LOG="$OUTPUT_DIR/latency-public-client.log"
rm -f "$LOG" "$CALL_LOG" "$LATENCY_CLIENT_LOG" "$OUTPUT_DIR"/acks/ack-*(N) "$OUTPUT_DIR"/acks/overlap-ack-*(N)
rm -f "$OUTPUT_DIR"/latency-*(N)

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
# The probe must run under the SAME macOS application host as a shipped
# application: AppKit owns the process main thread, the Cangjie entry runs on the
# runtime worker, and the renderer marshals its operations back to the main
# thread. Linking the launcher archive is what enables that main-thread dispatch;
# a bare cjc executable leaves it disabled, so any operation that reaches the
# native renderer from the worker is refused as NOT_MAIN_THREAD.
clang -fobjc-arc -fno-objc-msgsend-selector-stubs -fmodules -fstack-protector-strong \
  -isysroot "$SDKROOT_PATH" -mmacosx-version-min=12.0 \
  -c "$RUNTIME_DIR/native/cjgui_macos_application_launcher.m" \
  -o "$OUTPUT_DIR/native/cjgui_macos_application_launcher.o"
ar rcs "$OUTPUT_DIR/native/libcjgui_interaction_scheduling.a" \
  "$OUTPUT_DIR/native/cjgui_internal_renderer.o" "$OUTPUT_DIR/native/cjgui_native_bridge.o" \
  "$OUTPUT_DIR/native/cjgui_macos_application_launcher.o"

cjc --sysroot "$SDKROOT_PATH" --import-path "$SHARED_CORE" \
  "$RUNTIME_DIR/src/runtime_renderer_session.cj" \
  "$RUNTIME_DIR/src/composable_ui.cj" \
  "$RUNTIME_DIR/src/composable_ui_named_style.cj" \
  "$RUNTIME_DIR/src/composable_ui_component_instance.cj" \
  "$RUNTIME_DIR/src/composable_ui_window.cj" \
  "$RUNTIME_DIR/src/macos_application_host.cj" \
  "$PROBE_SRC" \
  -L "$SHARED_CORE" -lcjgui_shared_operation_core \
  -L "$OUTPUT_DIR/native" -lcjgui_interaction_scheduling \
  --link-options "-framework AppKit -framework Metal -framework MetalKit -framework QuartzCore -lobjc" \
  -o "$OUTPUT_DIR/interaction_scheduling_efficiency_probe"

export DYLD_LIBRARY_PATH="$CANGJIE_HOME/runtime/lib/darwin_aarch64_cjnative:${DYLD_LIBRARY_PATH:-}"
if [[ "$RUN_MODE" == "latency" ]]; then
  PROBE_ARGS=(--ack-dir "$LATENCY_DIR")
  PROBE_ARGS+=(--latency-only)
else
  PROBE_ARGS=(--ack-dir "$OUTPUT_DIR/acks")
  if [[ "$RUN_MODE" == "overlap" ]]; then
    PROBE_ARGS+=(--overlap-only)
  fi
fi
"$OUTPUT_DIR/interaction_scheduling_efficiency_probe" "${PROBE_ARGS[@]}" >"$LOG" 2>&1 &
PROBE_PID=$!

wait_for_descriptor() {
  local attempts=0
  while (( attempts < 240 )); do
    if rg -q '^CJGUI_INTERACTION_SCHEDULING_READY_DESCRIPTOR ' "$LOG" 2>/dev/null; then
      return 0
    fi
    if ! kill -0 "$PROBE_PID" 2>/dev/null; then
      print -u2 -- "interaction scheduling verifier: probe exited before next sample (previous=${previous_key:-:})"
      return 1
    fi
    sleep 0.05
    (( attempts += 1 ))
  done
  print -u2 -- "interaction scheduling verifier: timeout waiting for descriptor"
  return 1
}

extract_field() {
  local line="$1"
  local key="$2"
  print -r -- "$line" | awk -v key="$key" '{ for (i = 1; i <= NF; i++) if ($i ~ ("^" key "=")) { sub("^" key "=", "", $i); print $i; exit } }'
}

wait_for_ready() {
  local previous_key="$1"
  local attempts=0
  local line=""
  local key=""
  while (( attempts < 240 )); do
    line="$(rg '^CJGUI_INTERACTION_SCHEDULING_READY scale=' "$LOG" 2>/dev/null | tail -n 1 || true)"
    key="$(extract_field "$line" scale):$(extract_field "$line" sample)"
    if [[ -n "$line" && "$key" != ":" && "$key" != "$previous_key" ]]; then
      print -r -- "$line"
      return 0
    fi
    if ! kill -0 "$PROBE_PID" 2>/dev/null; then
      # This helper is invoked through command substitution, so it runs in a
      # subshell and cannot reap the verifier's child.  Let the parent perform
      # the final `wait` after reporting the malformed/incomplete sample.
      print -u2 -- "interaction scheduling verifier: probe exited before the next sample (previous=$previous_key); no further READY line"
      return 1
    fi
    sleep 0.05
    (( attempts += 1 ))
  done
  print -u2 -- "interaction scheduling verifier: timeout waiting for next sample (previous=$previous_key)"
  return 1
}

wait_for_overlap_ready() {
  local attempts=0
  local line=""
  while (( attempts < 240 )); do
    line="$(rg '^CJGUI_INTERACTION_SCHEDULING_OVERLAP_READY ' "$LOG" 2>/dev/null | tail -n 1 || true)"
    if [[ -n "$line" ]]; then
      print -r -- "$line"
      return 0
    fi
    if ! kill -0 "$PROBE_PID" 2>/dev/null; then
      print -u2 -- "interaction scheduling verifier: probe exited before OVERLAP_READY; no CJGUI_INTERACTION_SCHEDULING_OVERLAP_READY line to drive the overlap client"
      return 1
    fi
    sleep 0.05
    (( attempts += 1 ))
  done
  print -u2 -- "interaction scheduling verifier: timeout waiting for overlap descriptor"
  return 1
}

# Raw-artifact fingerprints for the focused latency run. Every measurement
# input (probe source, this script, the public driver, the transport/window/
# workspace/client sources, the linked shared-core library) and the built probe
# binary are hashed into one reproducible file inside the evidence directory.
write_latency_fingerprints() {
  local fingerprint_file="$OUTPUT_DIR/fingerprints.txt"
  : >"$fingerprint_file"
  local target=""
  for target in \
    "$PROBE_SRC" \
    "$SCRIPT_DIR/verify_interaction_scheduling_efficiency.sh" \
    "$LATENCY_CLIENT_SRC" \
    "$RUNTIME_DIR/shared_operation_core/src/shared_operation_transport.cj" \
    "$RUNTIME_DIR/src/composable_ui_window.cj" \
    "$RUNTIME_DIR/shared_operation_core/src/shared_text_document_workspace.cj" \
    "$CLIENT" \
    "$OUTPUT_DIR/interaction_scheduling_efficiency_probe" \
    "$SHARED_CORE_LIBRARY"; do
    if [[ -f "$target" ]]; then
      shasum -a 256 "$target" >>"$fingerprint_file"
    else
      print -r -- "MISSING  $target" >>"$fingerprint_file"
    fi
  done
}

# The probe must report an ENABLED main-thread dispatch: that is the observable
# consequence of running under the macOS application launcher. A disabled flag
# means the probe is a bare cjc process, and any renderer operation from the
# runtime worker would be refused before scheduling could be measured.
wait_for_host_state() {
  local attempts=0
  while (( attempts < 240 )); do
    if rg -q '^CJGUI_INTERACTION_SCHEDULING_HOST ' "$LOG" 2>/dev/null; then
      return 0
    fi
    if ! kill -0 "$PROBE_PID" 2>/dev/null; then
      return 1
    fi
    sleep 0.05
    (( attempts += 1 ))
  done
  return 1
}
wait_for_host_state \
  || { print -u2 -- "interaction scheduling verifier: probe did not report its host state"; exit 1; }
host_line="$(rg '^CJGUI_INTERACTION_SCHEDULING_HOST ' "$LOG" | tail -n 1)"
if ! print -r -- "$host_line" | rg -q 'dispatch_enabled=1'; then
  print -u2 -- "interaction scheduling verifier: main-thread dispatch is disabled ($host_line); the probe is not running under the macOS application launcher"
  exit 1
fi

wait_for_descriptor
DESCRIPTOR_PATH="$(rg '^CJGUI_INTERACTION_SCHEDULING_READY_DESCRIPTOR ' "$LOG" | tail -n 1 | awk '{print $2}')"
if [[ -z "$DESCRIPTOR_PATH" ]]; then
  print -u2 -- "interaction scheduling verifier: empty descriptor path"
  exit 1
fi

if [[ "$RUN_MODE" == "latency" ]]; then
  # One long-lived public driver, one request in flight at a time. The driver
  # waits for `latency-armed`; the probe waits for it too, so the driver's
  # single pre-measurement GET_CONTEXT cannot race the ready observer's
  # per-sample accounting.
  python3 "$LATENCY_CLIENT_SRC" "$DESCRIPTOR_PATH" --ack-dir "$LATENCY_DIR" --values 129-148 \
    >"$LATENCY_CLIENT_LOG" 2>&1 &
  CLIENT_PID=$!
  touch "$LATENCY_DIR/latency-armed"

  probe_status=0
  client_status=0
  wait "$CLIENT_PID" || client_status=$?
  wait "$PROBE_PID" || probe_status=$?
  write_latency_fingerprints

  if [[ "$probe_status" != "0" ]]; then
    print -u2 -- "interaction scheduling verifier: latency probe exited status=$probe_status"
  fi
  if [[ "$client_status" != "0" ]]; then
    print -u2 -- "interaction scheduling verifier: latency public client exited status=$client_status"
  fi

  rg '^CJGUI_INTERACTION_SCHEDULING_LATENCY_SAMPLE ' "$LOG" || true
  rg '^CJGUI_INTERACTION_SCHEDULING_LATENCY_CLIENT' "$LATENCY_CLIENT_LOG" || true

  sample_lines="$(rg -c '^CJGUI_INTERACTION_SCHEDULING_LATENCY_SAMPLE ' "$LOG" 2>/dev/null || true)"
  if [[ "$sample_lines" != "20" ]]; then
    print -u2 -- "interaction scheduling verifier: expected 20 latency sample lines, got ${sample_lines:-0}"
    exit 1
  fi
  response_files="$(ls "$LATENCY_DIR"/latency-response-*.txt 2>/dev/null | wc -l | tr -d ' ')"
  if [[ "$response_files" != "20" ]]; then
    print -u2 -- "interaction scheduling verifier: expected 20 raw invoke responses, got $response_files"
    exit 1
  fi
  if ! rg -q '^CJGUI_INTERACTION_SCHEDULING_LATENCY_RESULT samples=20 valid=true ' "$LOG"; then
    print -u2 -- "interaction scheduling verifier: probe latency result was not valid"
    exit 1
  fi
  if ! rg -q '^CJGUI_INTERACTION_SCHEDULING_LATENCY_CLIENT samples=20 valid=true ' "$LATENCY_CLIENT_LOG"; then
    print -u2 -- "interaction scheduling verifier: public latency client did not report success"
    exit 1
  fi
  if [[ "$probe_status" != "0" || "$client_status" != "0" ]]; then
    exit 1
  fi
  rg '^CJGUI_INTERACTION_SCHEDULING_LATENCY_RESULT ' "$LOG"
  print -r -- "interaction scheduling efficiency verification: PASS mode=latency samples=20 real_uds=1 one_request_in_flight=1 controlled_a_input=1 idle_clean=1 fingerprints=$OUTPUT_DIR/fingerprints.txt"
  exit 0
fi

if [[ "$RUN_MODE" == "full" ]]; then
  previous_key=":"
  sample_count=0
  while (( sample_count < 90 )); do
    line="$(wait_for_ready "$previous_key")"
    scale="$(extract_field "$line" scale)"
    sample="$(extract_field "$line" sample)"
    target="$(extract_field "$line" target)"
    value="$(extract_field "$line" value)"
    key="${scale}:${sample}"
    if [[ -z "$scale" || -z "$sample" || -z "$target" || -z "$value" ]]; then
      print -u2 -- "interaction scheduling verifier: malformed ready line: $line"
      exit 1
    fi
    version="$(python3 "$CLIENT" "$DESCRIPTOR_PATH" get --target "$target" | awk '$1 == "VERSION" { print $2; exit }')"
    if [[ -z "$version" ]]; then
      print -u2 -- "interaction scheduling verifier: no public version target=$target scale=$scale sample=$sample"
      exit 1
    fi
    print -r -- "CJGUI_INTERACTION_SCHEDULING_CALL scale=$scale sample=$sample target=$target expected_version=$version value=$value" >>"$CALL_LOG"
    python3 "$CLIENT" "$DESCRIPTOR_PATH" invoke "$version" SET_PREVIEW_LIMIT --target "$target" \
      --arg "value=INTEGER:$value" >>"$CALL_LOG"
    touch "$OUTPUT_DIR/acks/ack-${scale}-${sample}"
    previous_key="$key"
    sample_count=$((sample_count + 1))
  done

  if [[ "$(rg -c '^CJGUI_INTERACTION_SCHEDULING_CALL ' "$CALL_LOG")" != "90" ]]; then
    print -u2 -- "interaction scheduling verifier: expected 90 public calls"
    exit 1
  fi
  if [[ "$(rg -c '^APPLIED true$' "$CALL_LOG")" != "90" ]]; then
    print -u2 -- "interaction scheduling verifier: expected 90 applied public calls"
    exit 1
  fi
fi

overlap_line="$(wait_for_overlap_ready ":")"
overlap_target="$(extract_field "$overlap_line" target)"
overlap_ready_version="$(extract_field "$overlap_line" expected_version)"
overlap_value="$(extract_field "$overlap_line" value)"
# The READY line carries the version the probe observed while preparing the
# hold. In full mode the verifier itself issues 90 public writes between that
# observation and this step, so that value is stale by the time the frame
# reaches the owner and the CAS correctly rejects it as version_conflict. The
# overlap step wants an authorized external write during the hold, so it reads
# the current version immediately before sending and records both.
# The authoritative owner version is the last VERSION_AFTER this verifier
# itself observed: its own writes advanced the owner, while the READY line
# carries the B window controller's view, which had not yet observed them. A
# fresh public read cannot be used here because the probe is already inside the
# hold and no longer answers external reads.
overlap_owner_version=""
if [[ -f "$CALL_LOG" ]]; then
  overlap_owner_version="$(rg -o 'VERSION_AFTER [0-9]+' "$CALL_LOG" 2>/dev/null | tail -1 | awk '{print $2}' || true)"
fi
if [[ -n "$overlap_owner_version" ]]; then
  overlap_version="$overlap_owner_version"
else
  overlap_version="$overlap_ready_version"
fi
print -r -- "CJGUI_INTERACTION_SCHEDULING_OVERLAP_VERSION ready=$overlap_ready_version used=$overlap_version target=$overlap_target source=last-observed-version-after" >>"$CALL_LOG"
if [[ -z "$overlap_target" || -z "$overlap_version" || -z "$overlap_value" ]]; then
  print -u2 -- "interaction scheduling verifier: malformed overlap ready line: $overlap_line"
  exit 1
fi
OVERLAP_CALL_LOG="$OUTPUT_DIR/overlap-public-calls.log"
rm -f "$OVERLAP_CALL_LOG"
OVERLAP_START="$OUTPUT_DIR/acks/overlap-start-1"
rm -f "$OVERLAP_START"
python3 - "$DESCRIPTOR_PATH" "$overlap_version" "$overlap_target" "$overlap_value" "$OVERLAP_START" \
  >"$OVERLAP_CALL_LOG" 2>&1 <<'PY' &
import pathlib
import socket
import sys

descriptor_path, expected_version, target, base_value, start_path = sys.argv[1:]
lines = pathlib.Path(descriptor_path).read_text(encoding="utf-8").splitlines()
socket_path = bytes.fromhex(lines[1].split()[2]).decode("utf-8")
capability = bytes.fromhex(lines[2].split()[2]).decode("utf-8")

def invoke() -> str:
    value = int(base_value)
    payload = "\n".join([
        "PROTOCOL CJGUI_SHARED_OPERATION/2",
        f"AUTH {capability}",
        "INVOKE %s SET_PREVIEW_LIMIT 1 1" % expected_version,
        f"ID {target}",
        f"ARG value INTEGER {value}",
    ])
    encoded = payload.encode("utf-8")
    frame = str(len(encoded)).encode("ascii") + b"\n" + encoded
    received = bytearray()
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(3.0)
        connection.connect(socket_path)
        connection.sendall(frame)
        # The marker means the complete request frame is on the socket.  The
        # owner must still pump it; this process waits for the real response.
        pathlib.Path(start_path).touch()
        while True:
            chunk = connection.recv(4096)
            if not chunk:
                break
            received.extend(chunk)
    if b"\n" not in received:
        return "RESPONSE missing_frame"
    header, body = bytes(received).split(b"\n", 1)
    try:
        size = int(header)
    except ValueError:
        return "RESPONSE invalid_header"
    return "RESPONSE " + body[:size].decode("utf-8", errors="replace").replace("\n", "|")

print(invoke(), flush=True)
PY
overlap_pid=$!
if ! wait "$overlap_pid"; then
  print -u2 -- "interaction scheduling verifier: overlap UDS client failed"
  exit 1
fi
if [[ "$(rg -c 'APPLIED true' "$OVERLAP_CALL_LOG" 2>/dev/null || true)" != "1" ]]; then
  print -u2 -- "interaction scheduling verifier: overlap write was not applied"
  exit 1
fi
touch "$OUTPUT_DIR/acks/overlap-ack-1"

wait "$PROBE_PID"

rg '^CJGUI_INTERACTION_SCHEDULING_OVERLAP_RESULT valid=true ' "$LOG"
if [[ "$RUN_MODE" == "full" ]]; then
  for scale in 8 128 960; do
    if [[ "$(rg -c "^CJGUI_INTERACTION_SCHEDULING_SAMPLE scale=${scale} .*valid=true " "$LOG")" != "30" ]]; then
      print -u2 -- "interaction scheduling verifier: missing valid samples scale=$scale"
      exit 1
    fi
    rg "^CJGUI_INTERACTION_SCHEDULING_TERMINAL_COVERAGE scale=${scale} unrelated_activation=true rebind_suppression=true$" "$LOG"
    rg "^CJGUI_INTERACTION_SCHEDULING_SCALE scale=${scale} samples=30 valid=true$" "$LOG"
  done
  rg '^CJGUI_INTERACTION_SCHEDULING_SUMMARY scales_valid=true a_close_survives_b=true overlap_valid=true failed_candidate_retained=true failed_candidate_recovered=true idle_no_submit=true valid=true$' "$LOG"
  print -r -- "interaction scheduling efficiency verification: PASS mode=full scales=8,128,960 samples=90 real_uds=1 terminal_and_generic_split=1 overlap_atomic_backlog=1 b_owner_turn_bound=1 a_action_or_cancel=1 queue_bounded=1 a_close_survives_b=1 failed_candidate_retry=1 idle_no_submit=1"
else
  rg '^CJGUI_INTERACTION_SCHEDULING_OVERLAP_ONLY_SUMMARY overlap_valid=true closed_a=true b_remains_open=true valid=true$' "$LOG"
  print -r -- "interaction scheduling efficiency verification: PASS mode=overlap real_uds=1 overlap_atomic_backlog=1 b_owner_turn_bound=1 a_action_or_cancel=1 queue_bounded=1"
fi
