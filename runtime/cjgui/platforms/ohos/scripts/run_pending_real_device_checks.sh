#!/usr/bin/env bash
# 第九次工作包：本轮 HAP/目标设备/启动实例绑定的待验入口。
# 用法：bash run_pending_real_device_checks.sh --target <hdc connectkey> [--run-id <id>]
# 真实平台四项仍按登记表审阅；此脚本成功只代表入口内的两项探针通过。
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../../../.." && pwd)"
LAB="$REPO/labs/ohos_cjgui_app"
ARTIFACTS="$REPO/labs/ohos_cangjie_smoke/artifacts/cjgui-backend"
HAP="$LAB/entry/build/default/outputs/default/entry-default-unsigned.hap"
HDC_BINARY="${CJGUI_REAL_DEVICE_HDC_BINARY:-/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc}"
BUILD_SCRIPT="${CJGUI_REAL_DEVICE_BUILD_SCRIPT:-$HERE/build_and_run.sh}"
LIFECYCLE_PROBE="${CJGUI_REAL_DEVICE_LIFECYCLE_PROBE:-$HERE/verify_surface_lifecycle_probe.py}"
CLIPPING_PROBE="${CJGUI_REAL_DEVICE_CLIPPING_PROBE:-$HERE/verify_clipping_probe.py}"
RUN_ID="realref-$(date +%Y%m%d-%H%M%S)-$$"
TARGET=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) [ "$#" -ge 2 ] || { echo '缺 --target 值' >&2; exit 2; }; TARGET="$2"; shift 2 ;;
    --run-id) [ "$#" -ge 2 ] || { echo '缺 --run-id 值' >&2; exit 2; }; RUN_ID="$2"; shift 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done
[[ "$TARGET" =~ ^[A-Za-z0-9._:-]+$ ]] || { echo '需要明确合法的 --target connectkey' >&2; exit 2; }
[[ "$RUN_ID" =~ ^[A-Za-z0-9._-]+$ ]] || { echo 'run-id 含非法字符' >&2; exit 2; }
[ -d "$LAB/scripts" ] && [ -f "$HERE/verify_probe_op_coverage.py" ] || {
  echo "仓库根解析失败: REPO=$REPO" >&2; exit 1;
}
DEST="$ARTIFACTS/run/$RUN_ID"
mkdir -p "$ARTIFACTS/run" || exit 1
if ! mkdir "$DEST"; then
  echo "本轮 run-id 已存在，拒绝复用旧证据: $DEST" >&2
  exit 1
fi
mkdir "$DEST/verification" || exit 1
printf 'run_id=%s\ntarget=%s\nhap_requested=%s\n' "$RUN_ID" "$TARGET" "$HAP" \
  > "$DEST/requested_identity.txt"
export CJGUI_OHOS_RUN_ID="$RUN_ID" CJGUI_REAL_DEVICE_TARGET="$TARGET"
export CJGUI_OHOS_VERIFICATION_DIR="$DEST/verification"
export CJGUI_REAL_DEVICE_HDC_BINARY="$HDC_BINARY"
cat > "$DEST/hdc-target.sh" <<'HDC_WRAPPER'
#!/usr/bin/env bash
exec "$CJGUI_REAL_DEVICE_HDC_BINARY" -t "$CJGUI_REAL_DEVICE_TARGET" "$@"
HDC_WRAPPER
chmod 700 "$DEST/hdc-target.sh"
export HDC="$DEST/hdc-target.sh"

finish() {
  local status="$1" reason="$2" code="$3"
  printf 'RESULT=%s\nreason=%s\nrun_id=%s\ntarget=%s\n' \
    "$status" "$reason" "$RUN_ID" "$TARGET" > "$DEST/result.txt"
  exit "$code"
}

LOCAL_PORT=""
FORWARD_CREATE_STARTED=0
FORWARD_CREATE_COLLECTING=0
FORWARD_CREATE_SIGNAL=""
FORWARD_OWNED=0
REMOTE_PORT=7856

record_forward_identity() {
  printf 'target=%s\nhost=127.0.0.1\nlocal_port=%s\ndevice_port=%s\ncreate_result=%s\n' \
    "$TARGET" "$LOCAL_PORT" "$REMOTE_PORT" "$1" > "$DEST/forward_identity.txt"
}

# fport ls 为全设备列表。第一端是本机端口，第二端是设备端口。
forward_map_check() {
  python3 - "$1" "$LOCAL_PORT" "$TARGET" "$2" "$REMOTE_PORT" <<'PY'
import pathlib
import re
import sys

path, local, target, mode, remote = (
    pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
lines = path.read_text(errors="replace").splitlines()
matches = []
for line in lines:
    match = re.search(r"(?:^|\s)(\S+)\s+tcp:(\d+)\s+(\S+)\s+\[Forward\]", line)
    if match and match.group(2) == local:
        matches.append((match.group(1), match.group(3)))
if mode == "before":
    if matches:
        print("old_or_other_target_mapping")
        sys.exit(1)
    print("local_port_unmapped")
    sys.exit(0)
if not matches and mode == "cleanup":
    print("already_absent")
    sys.exit(2)
if matches == [(target, f"tcp:{remote}")]:
    print("exact_target_mapping")
    sys.exit(0)
print(f"mapping_mismatch:{matches!r}")
sys.exit(1)
PY
}

on_exit() {
  local result_rc=$? list_rc=0 check_rc=0 remove_rc=0
  trap - EXIT
  trap '' INT TERM HUP
  # 完整的本轮成功回执才赋予清理权限；相同端点也可能由预检后的他方抢占。
  if [ "$FORWARD_OWNED" -eq 1 ]; then
    "$HDC_BINARY" fport ls > "$DEST/forward.cleanup.before.log" \
      2> "$DEST/forward.cleanup.list.stderr.log"
    list_rc=$?
    if [ "$list_rc" -eq 0 ]; then
      forward_map_check "$DEST/forward.cleanup.before.log" cleanup \
        > "$DEST/forward.cleanup.status"
      check_rc=$?
      if [ "$check_rc" -eq 0 ]; then
        "$HDC" fport rm "tcp:$LOCAL_PORT" "tcp:$REMOTE_PORT" \
          > "$DEST/forward.cleanup.stdout.log" \
          2> "$DEST/forward.cleanup.stderr.log"
        remove_rc=$?
        printf 'remove_exitcode=%s\n' "$remove_rc" \
          >> "$DEST/forward.cleanup.status"
        if [ "$remove_rc" -eq 0 ]; then
          "$HDC_BINARY" fport ls > "$DEST/forward.cleanup.after.log" \
            2> "$DEST/forward.cleanup.after.stderr.log"
          list_rc=$?
          if [ "$list_rc" -eq 0 ]; then
            forward_map_check "$DEST/forward.cleanup.after.log" before \
              >> "$DEST/forward.cleanup.status"
            check_rc=$?
            if [ "$check_rc" -eq 0 ]; then
              echo "removed" >> "$DEST/forward.cleanup.status"
            fi
          fi
        fi
      elif [ "$check_rc" -eq 2 ]; then
        check_rc=0
      else
        echo "skip_mismatch" >> "$DEST/forward.cleanup.status"
      fi
    fi
    if [ "$list_rc" -ne 0 ] || [ "$check_rc" -ne 0 ] || [ "$remove_rc" -ne 0 ]; then
      if grep -Fxq 'RESULT=FAIL' "$DEST/result.txt" 2>/dev/null; then
        echo 'forward_cleanup=failed' >> "$DEST/result.txt"
      else
        printf 'RESULT=FAIL\nreason=forward_cleanup_failed\nrun_id=%s\ntarget=%s\n' \
          "$RUN_ID" "$TARGET" > "$DEST/result.txt"
      fi
      result_rc=1
    fi
  else
    echo "not_owned_by_run" > "$DEST/forward.cleanup.status"
    if [ "$FORWARD_CREATE_STARTED" -eq 1 ]; then
      "$HDC_BINARY" fport ls > "$DEST/forward.cleanup.unowned.log" \
        2> "$DEST/forward.cleanup.unowned.stderr.log"
      printf 'unowned_list_exitcode=%s\n' "$?" >> "$DEST/forward.cleanup.status"
    fi
  fi
  if [ ! -s "$DEST/result.txt" ]; then
    printf 'RESULT=FAIL\nreason=unexpected_exit_%s\nrun_id=%s\ntarget=%s\n' \
      "$result_rc" "$RUN_ID" "$TARGET" > "$DEST/result.txt"
    result_rc=1
  fi
  echo "$(sed -n '1p' "$DEST/result.txt") $(sed -n '2p' "$DEST/result.txt") evidence=$DEST"
  exit "$result_rc"
}
trap on_exit EXIT
on_signal() {
  local signal_name="$1" signal_code="$2"
  if [ "$FORWARD_CREATE_COLLECTING" -eq 1 ]; then
    FORWARD_CREATE_SIGNAL="$signal_name"
    printf 'signal=%s\n' "$signal_name" >> "$DEST/forward.create.signals.log"
    return
  fi
  finish FAIL "signal_${signal_name}" "$signal_code"
}
trap 'on_signal INT 130' INT
trap 'on_signal TERM 143' TERM
trap 'on_signal HUP 129' HUP

python3 "$HERE/verify_probe_op_coverage.py" > "$DEST/coverage.stdout.log" \
  2> "$DEST/coverage.stderr.log" || finish FAIL coverage_preflight_failed 1

"$HDC_BINARY" list targets > "$DEST/targets.stdout.log" \
  2> "$DEST/targets.stderr.log" || finish FAIL hdc_list_targets_failed 1
if ! awk '{print $1}' "$DEST/targets.stdout.log" | grep -Fxq -- "$TARGET"; then
  finish FAIL target_not_connected 1
fi

# 唯一部署路径已执行 install -r、清日志、启动、PID/变体断言。不得二次卸载或安装。
VERIFY_TRANSPORT=1 TEST_GATES=1 bash "$BUILD_SCRIPT" "$LAB" --no-emulator-start \
  --verify-transport --test-gates --run-id "$RUN_ID" \
  > "$DEST/build.stdout.log" 2> "$DEST/build.stderr.log"
build_rc=$?
printf '%s\n' "$build_rc" > "$DEST/build.exitcode"
[ "$build_rc" -eq 0 ] || finish FAIL build_deploy_or_start_failed 1

bash "$HERE/check_real_ref_capability.sh" "$DEST" "$RUN_ID" "$HAP" "$TARGET" \
  > "$DEST/capability.stdout.log" 2> "$DEST/capability.stderr.log"
cap_rc=$?
cat "$DEST/capability.stdout.log"
case "$cap_rc" in
  0) ;;
  42) finish BLOCKED "$(sed -n 's/^VERDICT=BLOCKED reason=//p' "$DEST/capability.stdout.log" | tail -1)" 42 ;;
  *) finish FAIL current_build_or_launch_evidence_invalid 1 ;;
esac

# 每轮独立端口；明确 override 仅供受控环境重现占用/旧映射。
LOCAL_PORT="$(python3 - "${CJGUI_REAL_DEVICE_LOCAL_PORT:-}" <<'PY'
import socket
import sys

requested = sys.argv[1]
if requested:
    if not requested.isascii() or not requested.isdecimal():
        sys.exit(2)
    port = int(requested)
    if port < 1024 or port > 65535:
        sys.exit(2)
else:
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
print(port)
PY
)" || finish FAIL forward_port_selection_failed 1
record_forward_identity not_attempted

"$HDC_BINARY" fport ls > "$DEST/forward.before.stdout.log" \
  2> "$DEST/forward.before.stderr.log" || finish FAIL forward_list_before_failed 1
forward_map_check "$DEST/forward.before.stdout.log" before \
  > "$DEST/forward.before.assessment.log" || finish FAIL forward_old_mapping 1
python3 - "$LOCAL_PORT" > "$DEST/forward.bind.stdout.log" \
  2> "$DEST/forward.bind.stderr.log" <<'PY'
import socket
import sys
with socket.socket() as sock:
    sock.bind(("127.0.0.1", int(sys.argv[1])))
PY
bind_rc=$?
[ "$bind_rc" -eq 0 ] || finish FAIL forward_local_port_occupied 1

FORWARD_CREATE_STARTED=1
FORWARD_CREATE_COLLECTING=1
record_forward_identity attempting
export CJGUI_FORWARD_ENTRY_PID="$$"
# 由有界监督进程收取 HDC 的最终结果。入口收到信号时先等此结果落盘；
# 超时或监督进程失联都不能凭端点相同推断本轮拥有映射。
python3 - "$HDC" "$LOCAL_PORT" "$REMOTE_PORT" "$DEST" <<'PY'
import pathlib
import signal
import subprocess
import sys

hdc, local, remote, dest_arg = sys.argv[1:]
dest = pathlib.Path(dest_arg)
signals = []

def remember_signal(signum, _frame):
    signals.append(signal.Signals(signum).name)

for name in ("SIGINT", "SIGTERM", "SIGHUP"):
    signal.signal(getattr(signal, name), remember_signal)

state = "spawn_failed"
pid = "none"
rc = None
with (dest / "forward.create.stdout.log").open("wb") as stdout, \
        (dest / "forward.create.stderr.log").open("wb") as stderr:
    try:
        child = subprocess.Popen(
            [hdc, "fport", f"tcp:{local}", f"tcp:{remote}"],
            stdout=stdout, stderr=stderr, start_new_session=True)
        pid = str(child.pid)
        (dest / "forward.create.pid").write_text(pid + "\n")
        try:
            rc = child.wait(timeout=12)
            state = "completed"
        except subprocess.TimeoutExpired:
            state = "timeout"
            child.terminate()
            try:
                rc = child.wait(timeout=1)
            except subprocess.TimeoutExpired:
                child.kill()
                try:
                    rc = child.wait(timeout=1)
                except subprocess.TimeoutExpired:
                    state = "kill_unconfirmed"
    except OSError as exc:
        stderr.write(f"supervisor_spawn_error={exc!r}\n".encode())

(dest / "forward.create.exitcode").write_text(
    (str(rc) if rc is not None else "unknown") + "\n")
(dest / "forward.create.supervisor.log").write_text(
    f"state={state}\nchild_pid={pid}\nchild_exitcode={rc if rc is not None else 'unknown'}\n"
    f"supervisor_signals={','.join(signals) or 'none'}\n")
sys.exit(0 if state == "completed" else 1)
PY
supervisor_rc=$?
create_state="$(sed -n 's/^state=//p' "$DEST/forward.create.supervisor.log" 2>/dev/null | head -1)"
create_rc="$(cat "$DEST/forward.create.exitcode" 2>/dev/null)"
if [ "$create_state" = spawn_failed ]; then
  record_forward_identity spawn_failed
  finish FAIL forward_create_spawn_failed 1
fi
if [ "$supervisor_rc" -ne 0 ] || [ "$create_state" != completed ] \
    || [[ ! "$create_rc" =~ ^-?[0-9]+$ ]]; then
  [ -s "$DEST/forward.create.exitcode" ] || echo unknown > "$DEST/forward.create.exitcode"
  record_forward_identity result_unknown
  if [ -n "$FORWARD_CREATE_SIGNAL" ]; then
    finish FAIL forward_create_interrupted_result_unknown 1
  fi
  finish FAIL forward_create_result_unknown 1
fi
if [ "$create_rc" -ne 0 ]; then
  record_forward_identity "failed_exit_$create_rc"
  if [ -n "$FORWARD_CREATE_SIGNAL" ]; then
    finish FAIL forward_create_interrupted_failed 1
  fi
  finish FAIL forward_create_failed 1
fi
# 创建命令已返回成功；清理仍须在退出时核对精确 target+双端点。
record_forward_identity returned_ok_unconfirmed
if grep -Fq '[Fail]' "$DEST/forward.create.stdout.log" \
  "$DEST/forward.create.stderr.log"; then
  record_forward_identity reported_failure
  finish FAIL forward_create_reported_failure 1
fi
grep -Fq 'Forwardport result:OK' "$DEST/forward.create.stdout.log" \
  "$DEST/forward.create.stderr.log" || {
    record_forward_identity unconfirmed
    finish FAIL forward_create_unconfirmed 1
  }
# 退出码和明确成功回执共同构成本轮所有权依据。
FORWARD_OWNED=1
FORWARD_CREATE_COLLECTING=0
if [ -n "$FORWARD_CREATE_SIGNAL" ]; then
  record_forward_identity confirmed_creation_interrupted
  finish FAIL forward_create_interrupted_confirmed 1
fi
# 先前全局列表无此本机端口，且 HDC 回执证实本轮创建。
"$HDC_BINARY" fport ls > "$DEST/forward.after.stdout.log" \
  2> "$DEST/forward.after.stderr.log" || {
    record_forward_identity list_after_failed
    finish FAIL forward_list_after_failed 1
  }
forward_map_check "$DEST/forward.after.stdout.log" exact \
  > "$DEST/forward.after.assessment.log" || {
    record_forward_identity mapping_mismatch
    finish FAIL forward_mapping_mismatch 1
  }
record_forward_identity confirmed
export CJGUI_OHOS_HOST=127.0.0.1 CJGUI_OHOS_PORT="$LOCAL_PORT"

# HDC 列表正确仍须证明本机端点实际可连；随后两探针会走同一端点的协议连接。
python3 - "$LOCAL_PORT" > "$DEST/forward.socket.stdout.log" \
  2> "$DEST/forward.socket.stderr.log" <<'PY'
import socket
import sys
import time
port = int(sys.argv[1])
last = None
for _ in range(20):
    try:
        with socket.create_connection(("127.0.0.1", port), timeout=0.5):
            print(f"connected=127.0.0.1:{port}")
            sys.exit(0)
    except OSError as exc:
        last = exc
        time.sleep(0.25)
print(f"connect_failed={last!r}", file=sys.stderr)
sys.exit(1)
PY
socket_rc=$?
[ "$socket_rc" -eq 0 ] || finish FAIL forward_socket_unreachable 1

verify_forward_current() {
  local label="$1"
  "$HDC_BINARY" fport ls > "$DEST/$label.forward.stdout.log" \
    2> "$DEST/$label.forward.stderr.log" || finish FAIL forward_list_during_probe_failed 1
  forward_map_check "$DEST/$label.forward.stdout.log" exact \
    > "$DEST/$label.forward.assessment.log" || finish FAIL forward_mapping_changed 1
}

probe_result() {
  local kind="$1" stem="$2" marker="$3"
  python3 - "$DEST/verification" "$kind" "$stem" "$marker" \
    "$DEST/$kind.stdout.log" "$RUN_ID" "$TARGET" <<'PY'
import json
import pathlib
import re
import sys

directory, kind, stem, marker, stdout, run_id, target = (
    pathlib.Path(sys.argv[1]), sys.argv[2], sys.argv[3],
    pathlib.Path(sys.argv[4]), pathlib.Path(sys.argv[5]), sys.argv[6], sys.argv[7])
try:
    start = marker.stat().st_mtime_ns
    artifacts = [directory / f"{stem}_evidence.json", directory / f"{stem}_raw.json"]
    if any(not p.is_file() or p.stat().st_mtime_ns < start for p in artifacts):
        raise ValueError("missing_or_stale_probe_evidence")
    evidence, raw = [json.loads(p.read_text()) for p in artifacts]
    if not isinstance(raw, list) or not raw:
        raise ValueError("empty_raw_archive")
    checks = evidence.get("checks") if kind == "lifecycle" and isinstance(evidence, dict) else evidence
    if not isinstance(checks, list) or not checks:
        raise ValueError("missing_checks")
    marker_pattern = re.compile(r"^PROBE_INSTANCE run_id=" + re.escape(run_id)
        + r" target=" + re.escape(target) + r" pid=([1-9]\d*) token=(\S+)$")
    markers = [m for line in stdout.read_text().splitlines()
               if (m := marker_pattern.fullmatch(line))]
    if not markers:
        raise ValueError("missing_current_probe_instance")
    identity = (directory.parent / "run_identity.txt").read_text().splitlines()
    prior_tokens = {line.removeprefix("launch_token=") for line in identity
                    if line.startswith("launch_token=")}
    prior_pids = {line.removeprefix("launch_pid=") for line in identity
                  if line.startswith("launch_pid=")}
    if kind == "clipping":
        for line in (directory.parent / "lifecycle.stdout.log").read_text().splitlines():
            if m := marker_pattern.fullmatch(line):
                prior_pids.add(m.group(1))
                prior_tokens.add(m.group(2))
except (OSError, ValueError, json.JSONDecodeError) as exc:
    print(f"BLOCKED {kind}: {exc}")
    sys.exit(42)

tokens = [m.group(2) for m in markers]
pids = [m.group(1) for m in markers]
if (not prior_tokens or not prior_pids or len(set(tokens)) != len(tokens)
        or len(set(pids)) != len(pids)
        or any(token in prior_tokens for token in tokens)
        or any(pid in prior_pids for pid in pids)):
    print(f"FAIL {kind}: reused_or_missing_instance_pid_or_token")
    sys.exit(1)

if any(c.get("status") == "FAIL" or c.get("pass") is False for c in checks):
    print(f"FAIL {kind}: failed_check")
    sys.exit(1)
if any(c.get("status") == "BLOCKED" for c in checks):
    print(f"BLOCKED {kind}: blocked_check")
    sys.exit(42)
if not all(c.get("status") == "PASS" or c.get("pass") is True for c in checks):
    print(f"BLOCKED {kind}: unclassified_check")
    sys.exit(42)
print(f"PASS {kind}: {len(checks)} checks")
PY
}

run_probe() {
  local kind="$1" stem="$2" script="$3" rc assessment_rc
  : > "$DEST/$kind.started"
  python3 "$script" > "$DEST/$kind.stdout.log" 2> "$DEST/$kind.stderr.log"
  rc=$?
  grep '^PROBE_INSTANCE ' "$DEST/$kind.stdout.log" \
    > "$DEST/$kind.instances.txt" || true
  printf '%s\n' "$rc" > "$DEST/$kind.exitcode"
  if [ "$rc" -ne 0 ]; then
    echo "FAIL $kind: probe_exit_$rc" > "$DEST/$kind.assessment.log"
    return 1
  fi
  probe_result "$kind" "$stem" "$DEST/$kind.started" \
    > "$DEST/$kind.assessment.log" 2>&1
  assessment_rc=$?
  case "$assessment_rc" in
    0|42) return "$assessment_rc" ;;
    *) return 1 ;;
  esac
}

verify_forward_current lifecycle
run_probe lifecycle surface_lifecycle "$LIFECYCLE_PROBE"
lifecycle_rc=$?
verify_forward_current clipping
run_probe clipping clipping "$CLIPPING_PROBE"
clipping_rc=$?
printf 'lifecycle=%s\nclipping=%s\n' "$lifecycle_rc" "$clipping_rc" \
  > "$DEST/probe_exit_summary.txt"
if [ "$lifecycle_rc" -eq 1 ] || [ "$clipping_rc" -eq 1 ]; then
  finish FAIL probe_failed 1
fi
if [ "$lifecycle_rc" -ne 0 ] || [ "$clipping_rc" -ne 0 ]; then
  finish BLOCKED probe_evidence_or_required_check_missing 42
fi
finish PASS lifecycle_and_clipping_probes_passed 0
