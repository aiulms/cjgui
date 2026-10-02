#!/usr/bin/env zsh
# M3（2026-09-30）：普通第二消费者的快速连打/选区替换/拒绝恢复——每个**接受**
# 意图恰好一笔 owner 事务。与既有 real-input/grapheme 脚本同一驱动机制
# （CGEvent → 窗口服务器 → AppKit NSEvent；合成键盘，非人工物理输入）。
#
# 判别（期望独立于被测链：状态 AX 的 bytes/edits 与关闭后 owner 全文读回）：
#   1. 快速连打 10 个 ASCII 字符 ⇒ owner edits 恰 +10（不多笔合并、不丢笔），
#      owner bytes +10；插入链全经 kind-51（全值伴随只记账，leaked=0）。
#   2. Shift+Left×3 选 3 字符 + 键入 'X' ⇒ 替换**恰好一笔**（edits +1，
#      bytes -3+1），不是先删后插两笔。
#   3. RANGE_TEXT_REFUSE_FIRST=1 ⇒ store 首笔强制具名冲突：owner 拒绝 +1、
#      正文/字节不变；随后的键入经会话恢复**恰好一笔**落盘（applied 增 1），
#      三类守恒 decisions==accepted+refused+zero_write 保持。
# 边界：真实 IME 组字不在本脚本；拒绝探针是 store 的显式钩子（forced_probe_refusal）。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/range_text_window_app"
OUTPUT_DIR="${CJGUI_RANGE_TEXT_BURST_TMPDIR:-/private/tmp/cjgui-range-text-window-burst}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
if [[ -n "${CJ_GUI_SDKROOT:-}" && -d "$CJ_GUI_SDKROOT" ]]; then
  export SDKROOT="$CJ_GUI_SDKROOT"
else
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

CORPUS=$'M3 burst corpus\nline two\n'
export RANGE_TEXT_INITIAL="$CORPUS"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/burst-replace.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -40 "$LOG"; echo "range text window burst replace: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -40 "$LOG"; echo "range text window burst replace: BLOCKED $1" >&2; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

APP_PID=""
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
CANDIDATE_EXECS=("")
CANDIDATE_DIRS=()
CANDIDATE_DESCS=()

cleanup() {
  if [[ -n "$APP_PID" ]]; then
    cjgui_terminate_owned "$APP_PID" "" "${ROUND_EXEC:-}" "${ROUND_DIR:-$WORK}" || true
  fi
  cjgui_reclaim_candidates log || true
}
trap cleanup EXIT

session_locked && blocked "the session is locked; real posted input cannot be delivered"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc is required for the real input driver"
DRIVER="$WORK/desktop_input_driver"
swiftc -O "$RUNTIME_DIR/native/tests/desktop_input_driver.swift" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1 \
  || blocked "the real input driver did not build"
AX_PROBE="$WORK/ax_focus_probe"
swiftc -O "$RUNTIME_DIR/native/tests/ax_focus_probe.swift" -o "$AX_PROBE" > "$WORK/ax-probe-build.log" 2>&1 \
  || blocked "the AX focus probe did not build"
real_input_preflight || blocked "synthetic event posting is refused (Accessibility permission missing)"
log "step0 driver=built probe=built preflight=granted"

NAME_TOKEN="CJGUIRangeTextConsumer"
SUFFIX="Br${RUN_TAG//-/}"
BUNDLE_TOKEN="org.cangjie.cjgui.range-text-consumer.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "$SUFFIX" "$BUNDLE_TOKEN" \
  || blocked "could not prepare the per-round application copy"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app/Contents/MacOS/${NAME_TOKEN}${SUFFIX}"
CANDIDATE_EXECS=("${NAME_TOKEN}${SUFFIX}")
CANDIDATE_DIRS=("$ROUND_DIR")
[[ -x "${ROUND_DIR}/run.sh" ]] || blocked "round copy has no run.sh"

STDOUT_LOG="$WORK/app.log"
launch_round() { # $1 = extra env assignments
  ( cd "$ROUND_DIR" && env $1 nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
  local waited=0 ready=""
  while (( waited < 900 )); do
    ready="$(grep '^RANGE_TEXT_READY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
    [[ -n "$ready" ]] && break
    sleep 2; waited=$(( waited + 2 ))
  done
  [[ -n "$ready" ]] || blocked "the consumer never published RANGE_TEXT_READY (see $STDOUT_LOG)"
  log "ready $ready"
}

# 状态 AX 与焦点探针（与 grapheme 脚本同一锚定方案；AppleScript 先落变量再
# 解析，避免 $() 内嵌转义引号的解析问题）。
ax_body_value() {
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    repeat with w in windows of p
      try
        repeat with e in (every text area of w)
          try
            if (value of attribute \"AXIdentifier\" of e) is \"range-text-body\" then
              try
                return (value of e) as string
              on error
                return \"no_value\"
              end try
            end if
          end try
        end repeat
      end try
    end repeat
    return \"missing\"
  end tell" 2>&1 | awk '{lines[NR]=$0} END{last=0; for(i=NR;i>=1;i--){if(lines[i]!=""){last=i;break}} for(j=1;j<=last;j++) print lines[j]}' || true
}
ax_status_value() {
  local kind v
  for kind in "UI element" "text field" "static text"; do
    v="$(cjgui_ax 20 -e "tell application \"System Events\"
      set p to first process whose unix id is $APP_PID
      repeat with w in windows of p
        try
          repeat with e in (every $kind of w)
            try
              if (value of attribute \"AXIdentifier\" of e) is \"range-text-status\" then
                try
                  return (value of e) as string
                on error
                  return \"no_value\"
                end try
              end if
            end try
          end repeat
        end try
      end repeat
      return \"missing\"
    end tell" 2>&1 | awk '{lines[NR]=$0} END{last=0; for(i=NR;i>=1;i--){if(lines[i]!=""){last=i;break}} for(j=1;j<=last;j++) print lines[j]}' || true)"
    if [[ -n "$v" && "$v" != "missing" ]]; then
      print -r -- "$v"
      return 0
    fi
  done
  print -r -- "missing"
}
status_field() {
  local name="$1" value
  value="$(ax_status_value)"
  print -r -- "$value" | tr ' ' '\n' | awk -F= -v k="$name" '$1 == k {print $2; exit}'
}
body_frame() {
  local kind f
  for kind in "UI element" "text area" "text field"; do
    f="$(ax_identifier_frame "range-text-body" "$kind")"
    if [[ -n "$f" && "$f" != "missing" ]] && frame_is_positive "$f"; then
      print -r -- "$f"
      return 0
    fi
  done
  print -r -- "missing"
  return 1
}
ax_focus_caret() {
  "$AX_PROBE" "$APP_PID" "range-text-body" 2>/dev/null | awk '/^node /{for(i=1;i<=NF;i++) if($i ~ /^caret=/){sub("caret=","",$i); print $i}}' | head -1
}
app_focused() {
  "$AX_PROBE" "$APP_PID" "range-text-body" 2>/dev/null | awk '/^app_focused /{print; exit}' \
    | tr ' ' '\n' | awk -F= '$1=="focus"{print $2; exit}'
}
wait_status_bytes() {
  local expected="$1" attempts="${2:-40}" i=0 got=""
  while (( i < attempts )); do
    got="$(status_field bytes)"
    [[ "$got" == "$expected" ]] && { print -r -- "$got"; return 0; }
    sleep 0.35; i=$(( i + 1 ))
  done
  print -r -- "${got:-missing}"; return 1
}
wait_status_edits_at_least() {
  local expected="$1" attempts="${2:-40}" i=0 got=""
  while (( i < attempts )); do
    got="$(status_field edits)"
    [[ "$got" == <-> && "$got" -ge "$expected" ]] && { print -r -- "$got"; return 0; }
    sleep 0.35; i=$(( i + 1 ))
  done
  print -r -- "${got:-missing}"; return 1
}
owner_summary() {
  grep '^RANGE_TEXT_SUMMARY' "$STDOUT_LOG" 2>/dev/null | tail -1
}
sum_field() { print -r -- "$1" | tr ' ' '\n' | awk -F= -v k="$2" '$1 == k {print $2; exit}'; }

focus_body_end() {
  real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.txt" 2>&1 || true
  local attempt=0
  while (( attempt < 3 )); do
    activate_app
    sleep 0.8
    [[ "$(app_frontmost)" == "true" ]] && break
    attempt=$(( attempt + 1 ))
  done
  [[ "$(app_frontmost)" == "true" ]] || blocked "the application did not become frontmost"
  local body_frame="$(body_frame)"
  [[ -n "$body_frame" && "$body_frame" != "missing" ]] || blocked "range-text-body has no positive frame"
  local bx by bw bh
  read -r bx by bw bh <<< "$body_frame"
  "$DRIVER" click $(( bx + bw - 6 )) $(( by + bh - 6 )) >> "$WORK/driver.log" 2>&1 || true
  sleep 0.6
  [[ "$(app_focused)" == "1" ]] || blocked "the platform text adapter did not take real keyboard focus"
}

# ---- 运行 A：快速连打 + 选区替换（每接受意图恰好一笔）----
launch_round ""
APP_PID="$(cjgui_unique_round_pid "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "no single round-owned pid"
cjgui_unique_round_owns "$APP_PID" "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || blocked "the pid is not this round's instance"
AX_PID="$APP_PID"
log "step1 pid=$APP_PID"

focus_body_end
B0="$(status_field bytes)"
E0="$(status_field edits)"
[[ "$B0" == <-> && "$E0" == <-> ]] || fail "baseline status missing (bytes=$B0 edits=$E0)"
log "step2 baseline bytes=$B0 edits=$E0"

# 快速连打：一条 type 指令逐字符投递 10 个 ASCII 键入。
drive type "abcdefghij" || blocked "burst typing undelivered"
wait_status_bytes $(( B0 + 10 )) 40 >/dev/null \
  || fail "burst did not land byte-exactly (bytes $(status_field bytes), expected $(( B0 + 10 )))"
E1="$(status_field edits)"
[[ "$E1" == $(( E0 + 10 )) ]] \
  || fail "10-char burst must be EXACTLY 10 owner transactions (edits ${E0}->${E1})"
log "step3 burst_typing=pass bytes=${B0}->$(status_field bytes) edits=${E0}->${E1}"

# 选区替换：Shift+Left×3 选 3 字符 + 键入 'X' ⇒ 恰好一笔（删除+插入合一事务）。
drive shortcut shift 123 || blocked "shift-left#1 undelivered"
drive shortcut shift 123 || blocked "shift-left#2 undelivered"
drive shortcut shift 123 || blocked "shift-left#3 undelivered"
sleep 0.5
E2="$(status_field edits)"
[[ "$E2" == "$E1" ]] || fail "selection expansion must not write (edits ${E1}->${E2})"
drive type "X" || blocked "replacement typing undelivered"
wait_status_bytes $(( B0 + 10 - 3 + 1 )) 40 >/dev/null \
  || fail "replacement did not land byte-exactly (bytes $(status_field bytes), expected $(( B0 + 8 )))"
E3="$(status_field edits)"
[[ "$E3" == $(( E2 + 1 )) ]] \
  || fail "selection replacement must be EXACTLY one owner transaction (edits ${E2}->${E3})"
log "step4 replacement=pass edits=${E2}->${E3} one_transaction"

close_round() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    try
      click button 1 of window 1 of p
      return \"pressed\"
    on error
      return \"missing\"
    end try
  end tell" > "$WORK/close.txt" 2>&1 || true
  local waited=0 line=""
  while (( waited < 90 )); do
    line="$(owner_summary)"
    [[ -n "$line" ]] && break
    sleep 1; waited=$(( waited + 1 ))
  done
  [[ -n "$line" ]] || fail "no RANGE_TEXT_SUMMARY after close"
  print -r -- "$line"
}
SUMMARY_A="$(close_round)"
log "step5 $SUMMARY_A"
[[ "$(sum_field "$SUMMARY_A" leaked_range_events)" == "0" ]] \
  || fail "a second write path leaked: $SUMMARY_A"
[[ "$(sum_field "$SUMMARY_A" applied)" == "$(( E0 + 11 ))" ]] \
  || fail "run A applied != E0+11 (burst 10 + replace 1): $SUMMARY_A"
[[ "$(sum_field "$SUMMARY_A" rejected)" == "0" ]] \
  || fail "run A owner refused: $SUMMARY_A"
# M4 逐类别成本判别：每笔接受写入一行 workload 快照——raster 随写入单调递增，
# 且与纯选区/导航段（edits 不变）可区分；逐笔原数落日志。
typeset -a WORKLOAD_STEPS
WORKLOAD_STEPS=("${(@f)$(grep '^RANGE_TEXT_WORKLOAD_STEP' "$STDOUT_LOG" 2>/dev/null || true)}")
(( ${#WORKLOAD_STEPS[@]} >= 11 )) \
  || fail "expected >= 11 per-write workload snapshots (burst 10 + replace 1), got ${#WORKLOAD_STEPS[@]}"
prev_raster=0
for wline in "${WORKLOAD_STEPS[@]}"; do
  log "workload_step $wline"
  r="$(print -r -- "$wline" | tr ' ' '\n' | awk -F '[=/]' '$1=="raster"{print $2; exit}')"
  [[ "$r" == <-> ]] || fail "workload step missing raster count: $wline"
  (( r >= prev_raster )) || fail "workload raster not monotonic: $wline (prev=$prev_raster)"
  prev_raster=$r
done
log "workload_steps=pass count=${#WORKLOAD_STEPS[@]} final_raster=$prev_raster"

# ---- 运行 B：拒绝恢复（store 首笔强制具名冲突）----
export RANGE_TEXT_REFUSE_FIRST=1
launch_round ""
APP_PID="$(cjgui_unique_round_pid "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "no single round-owned pid (run B)"
cjgui_unique_round_owns "$APP_PID" "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || blocked "the pid is not this round's instance (run B)"
AX_PID="$APP_PID"
log "step6 pid=$APP_PID run=B refuse_first=1"

focus_body_end
BR0="$(status_field bytes)"
ER0="$(status_field edits)"
log "step7 baseline bytes=$BR0 edits=$ER0"

# 首笔键入被 store 强制拒绝：正文不变、owner rejected +1。
drive type "Q" || blocked "refusal-probe typing undelivered"
sleep 1.2
BR1="$(status_field bytes)"
[[ "$BR1" == "$BR0" ]] || fail "refused edit must not change bytes (bytes ${BR0}->${BR1})"
ER1="$(status_field edits)"
[[ "$ER1" == "$ER0" ]] || fail "refused edit must not apply (edits ${ER0}->${ER1})"
log "step8 refused=pass bytes_unchanged=${BR1} edits_unchanged=${ER1}"

# 恢复：下一笔键入经会话恢复恰好一笔落盘。
drive type "R" || blocked "recovery typing undelivered"
wait_status_bytes $(( BR0 + 1 )) 40 >/dev/null \
  || fail "recovery typing did not land byte-exactly (bytes $(status_field bytes), expected $(( BR0 + 1 )))"
ER2="$(status_field edits)"
[[ "$ER2" == $(( ER0 + 1 )) ]] \
  || fail "recovery must be EXACTLY one owner transaction (edits ${ER0}->${ER2})"
log "step9 recovery=pass edits=${ER0}->${ER2}"

SUMMARY_B="$(close_round)"
log "step10 $SUMMARY_B"
[[ "$(sum_field "$SUMMARY_B" rejected)" == "1" ]] \
  || fail "run B owner rejected != 1: $SUMMARY_B"
[[ "$(sum_field "$SUMMARY_B" applied)" == "1" ]] \
  || fail "run B applied != 1 (only the recovery write): $SUMMARY_B"
[[ "$(sum_field "$SUMMARY_B" leaked_range_events)" == "0" ]] \
  || fail "run B leaked a second write path: $SUMMARY_B"
acceptedB="$(sum_field "$SUMMARY_B" session_accepted)"
refusedB="$(sum_field "$SUMMARY_B" session_refused)"
decisionsB="$(sum_field "$SUMMARY_B" range_decisions)"
zeroWriteB="$(sum_field "$SUMMARY_B" zero_write_selections)"
[[ "$decisionsB" == "$(( acceptedB + refusedB + zeroWriteB ))" ]] \
  || fail "conservation broken: decisions=$decisionsB accepted=$acceptedB refused=$refusedB zero=$zeroWriteB"

log "PASS burst=10tx replace=1tx refusal=1recovered=1tx conservation=ok"
echo "range text window burst replace: PASS applied=11+1 rejected=1 log=$LOG"
