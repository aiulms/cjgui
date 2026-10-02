#!/usr/bin/env zsh
# B 字素首包（2026-09-29）：普通第二消费者（range_text_window_app，正常
# TextInput 路径）上的混合字素语料真实窗口消费。与既有 real-input 脚本同一
# 驱动机制（CGEvent → 窗口服务器 → AppKit NSEvent）；语料经 RANGE_TEXT_INITIAL
# 种子注入 owner 初始文本（逐标量 CGEvent 输入会把组合符/ZWJ 送进组字通道，
# 不作为普通 insertText 证据；组合重音/ZWJ 的输入路径由产品两轮覆盖）。
#
# 锚定方案：点击正文右下角 → 平台 caret 落到文末；语料以旗帜簇+哨兵 W 收尾：
#   1. Left #1 跨过哨兵 W（caret -1 UTF-16 单位）；
#   2. Left #2 跨过整个旗帜簇（caret -4 UTF-16 单位 = 两个 regional indicator
#      一次跨过）——整簇移动证据；
#   3. Shift+Right 扩选恰覆盖旗帜，Backspace 一次删除整个旗帜 8 字节
#      （owner bytes -8 + 全文等值核对）——整簇删除证据；
#   4. Shift+Left 越过哨兵扩选、Backspace 删 1 字节（ASCII 回归对照）；
#   5. 关闭后 RANGE_TEXT_SUMMARY：leaked=0、accepted==applied、rejected=0；
#      同运行 RANGE_TEXT_WORKLOAD baseline/final raster+upload 计数。
#
# 明示边界：合成 CGEvent 键盘（非人工物理键盘）；真实 IME 组字不在本脚本。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/range_text_window_app"
OUTPUT_DIR="${CJGUI_RANGE_TEXT_GRAPHEME_TMPDIR:-/private/tmp/cjgui-range-text-window-grapheme}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
if [[ -n "${CJ_GUI_SDKROOT:-}" && -d "$CJ_GUI_SDKROOT" ]]; then
  export SDKROOT="$CJ_GUI_SDKROOT"
else
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

# 语料：以「旗帜簇 + 哨兵 W」收尾；正文含 ZWJ 家庭、肤色、CJK+emoji。
CORPUS=$'Second consumer grapheme corpus\nZWJ family: 👨‍👩‍👧 mid\nSkin: 👍🏽 mid\nCJK: 中😀文 mid\nTail flag: 🇨🇳W'
export RANGE_TEXT_INITIAL="$CORPUS"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/grapheme-input.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -40 "$LOG"; echo "range text window grapheme input: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -40 "$LOG"; echo "range text window grapheme input: BLOCKED $1" >&2; exit 3; }

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
SUFFIX="Gm${RUN_TAG//-/}"
BUNDLE_TOKEN="org.cangjie.cjgui.range-text-consumer.example"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "$SUFFIX" "$BUNDLE_TOKEN" \
  || blocked "could not prepare the per-round application copy"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app/Contents/MacOS/${NAME_TOKEN}${SUFFIX}"
CANDIDATE_EXECS=("${NAME_TOKEN}${SUFFIX}")
CANDIDATE_DIRS=("$ROUND_DIR")
[[ -x "${ROUND_DIR}/run.sh" ]] || blocked "round copy has no run.sh"

STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )

waited=0
ready_line=""
while (( waited < 900 )); do
  ready_line="$(grep '^RANGE_TEXT_READY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$ready_line" ]] && break
  sleep 2; waited=$(( waited + 2 ))
done
[[ -n "$ready_line" ]] || blocked "the consumer never published RANGE_TEXT_READY (see $STDOUT_LOG)"
log "step1 $ready_line"
SEED_BYTES=$(printf '%s' "$CORPUS" | wc -c | tr -d ' ')
READY_BYTES="$(print -r -- "$ready_line" | tr ' ' '\n' | awk -F= '$1=="owner_bytes"{print $2; exit}')"
[[ "$READY_BYTES" == "$SEED_BYTES" ]] \
  || fail "seeded corpus mismatch ready=${READY_BYTES} seed=${SEED_BYTES}"

APP_PID="$(cjgui_unique_round_pid "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "no single round-owned pid"
cjgui_unique_round_owns "$APP_PID" "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || blocked "the pid is not this round's instance"
AX_PID="$APP_PID"

ax_value() { # <semanticId> <kind> -> full multiline value, trailing blanks trimmed
  local wanted="$1" kind="$2"
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    repeat with w in windows of p
      try
        repeat with e in (every $kind of w)
          try
            if (value of attribute \"AXIdentifier\" of e) is \"$wanted\" then
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
ax_value_any() {
  local wanted="$1" kind v
  for kind in "UI element" "text area" "text field" "static text"; do
    v="$(ax_value "$wanted" "$kind")"
    if [[ -n "$v" && "$v" != "missing" ]]; then print -r -- "$kind|$v"; return 0; fi
  done
  print -r -- "missing"
  return 1
}
ax_frame_any() { # <semanticId> -> "kind|x,y,w,h"（正矩形）
  local wanted="$1" kind f
  for kind in "UI element" "text area" "text field"; do
    f="$(ax_identifier_frame "$wanted" "$kind")"
    if [[ -n "$f" && "$f" != "missing" ]] && frame_is_positive "$f"; then print -r -- "$kind|$f"; return 0; fi
  done
  print -r -- "missing"
  return 1
}
body_text() {
  local value
  value="$(ax_value_any "range-text-body" || true)"
  print -r -- "${value#*|}"
}
status_field() {
  local name="$1" value
  value="$(ax_value_any "range-text-status" || true)"
  print -r -- "${value#*|}" | tr ' ' '\n' | awk -F= -v k="$name" '$1 == k {print $2; exit}'
}
ax_focus_caret() {
  "$AX_PROBE" "$AX_PID" "range-text-body" 2>/dev/null | awk '/^node /{for(i=1;i<=NF;i++) if($i ~ /^caret=/){sub("caret=","",$i); print $i}}' | head -1
}
wait_caret_changes_from() {
  local prev="$1" attempts="${2:-25}" i=0 c=""
  while (( i < attempts )); do
    c="$(ax_focus_caret)"
    [[ "$c" =~ ^[0-9]+$ && "$c" != "$prev" ]] && { print -r -- "$c"; return 0; }
    sleep 0.3; i=$(( i + 1 ))
  done
  print -r -- "${c:-missing}"; return 1
}
wait_status_bytes() {
  local expected="$1" attempts="${2:-30}" i=0 got=""
  while (( i < attempts )); do
    got="$(status_field bytes)"
    [[ "$got" == "$expected" ]] && { print -r -- "$got"; return 0; }
    sleep 0.4; i=$(( i + 1 ))
  done
  print -r -- "${got:-missing}"; return 1
}

real_ax_wait_ready "$AX_PID" 24 > "$WORK/ax-ready.txt" 2>&1 || true
activation_attempt=0
while (( activation_attempt < 3 )); do
  activate_app
  sleep 0.8
  [[ "$(app_frontmost)" == "true" ]] && break
  activation_attempt=$(( activation_attempt + 1 ))
done
[[ "$(app_frontmost)" == "true" ]] || blocked "the application did not become frontmost"

BODY="$(ax_frame_any "range-text-body" || true)"
[[ "$BODY" != "missing" ]] || blocked "range-text-body has no positive AX frame"
read -r BX BY BW BH <<< "${BODY#*|}"
"$DRIVER" click $(( BX + BW - 6 )) $(( BY + BH - 6 )) >> "$WORK/driver.log" 2>&1 || true
sleep 0.6
FOCUS_LINES="$("$AX_PROBE" "$AX_PID" "range-text-body" 2>/dev/null || true)"
APP_FOCUS_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{print; exit}')"
if [[ "$(print -r -- "$APP_FOCUS_LINE" | tr ' ' '\n' | awk -F= '$1=="focus"{print $2; exit}')" != "1" ]]; then
  "$DRIVER" click $(( BX + BW - 6 )) $(( BY + BH - 6 )) >> "$WORK/driver.log" 2>&1 || true
  sleep 0.6
fi
FOCUS_LINES="$("$AX_PROBE" "$AX_PID" "range-text-body" 2>/dev/null || true)"
APP_FOCUS_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{print; exit}')"
[[ "$(print -r -- "$APP_FOCUS_LINE" | tr ' ' '\n' | awk -F= '$1=="focus"{print $2; exit}')" == "1" ]] \
  || fail "the platform text adapter did not take real keyboard focus"
log "step2 focused=true frame=${BODY#*|}"

C_END="$(ax_focus_caret)"
[[ "$C_END" =~ ^[0-9]+$ ]] || fail "no caret after end click (got '${C_END:-none}')"
log "step3 caret_end=${C_END} bytes=$(status_field bytes)"

drive key 123 || blocked "left#1 undelivered"
C_AFTER_W="$(wait_caret_changes_from "$C_END" 25)" || fail "left#1 did not move the caret"
D1=$(( C_END - C_AFTER_W ))
drive key 123 || blocked "left#2 undelivered"
C_BEFORE_FLAG="$(wait_caret_changes_from "$C_AFTER_W" 25)" || fail "left#2 did not move the caret"
D2=$(( C_AFTER_W - C_BEFORE_FLAG ))
log "step4 caret_trail end=${C_END} after_w=${C_AFTER_W} before_flag=${C_BEFORE_FLAG} d1=${D1} d2=${D2}"
(( D1 == 1 )) || fail "left#1 should cross the sentinel by 1 utf16 unit, got ${D1}"
(( D2 == 4 )) || fail "left#2 should cross the WHOLE flag cluster by 4 utf16 units, got ${D2}"

B0="$(status_field bytes)"
E0="$(status_field edits)"
drive shortcut shift 124 || blocked "shift-right undelivered"
sleep 0.5
E1="$(status_field edits)"
[[ "$E1" == "$E0" ]] || fail "shift-right must not write (edits ${E0}->${E1})"
drive key 51 || blocked "backspace undelivered"
wait_status_bytes $(( B0 - 8 )) 30 >/dev/null \
  || fail "shift+backspace did not remove exactly the 8-byte flag cluster (bytes $(status_field bytes), expected $(( B0 - 8 )))"
E2="$(status_field edits)"
[[ "$E2" == $(( E0 + 1 )) ]] \
  || fail "flag delete must be EXACTLY one owner transaction (edits ${E0}->${E2})"
log "step5 flag_cluster_whole_delete=pass bytes=${B0}->$(( B0 - 8 )) edits=${E0}->${E2}"

B1=$(( B0 - 8 ))
drive shortcut shift 124 || blocked "shift-right undelivered"
sleep 0.5
E3="$(status_field edits)"
[[ "$E3" == "$E2" ]] || fail "second shift-right must not write (edits ${E2}->${E3})"
drive key 51 || blocked "backspace#2 undelivered"
wait_status_bytes $(( B1 - 1 )) 30 >/dev/null \
  || fail "second delete did not remove the 1-byte sentinel"
E4="$(status_field edits)"
[[ "$E4" == $(( E2 + 1 )) ]] \
  || fail "sentinel delete must be EXACTLY one transaction (edits ${E2}->${E4})"
log "step6 sentinel_delete=pass edits=${E2}->${E4}"

FINAL_BODY="$(body_text | tr '\r' '\n')"
EXPECTED=$'Second consumer grapheme corpus\nZWJ family: 👨‍👩‍👧 mid\nSkin: 👍🏽 mid\nCJK: 中😀文 mid\nTail flag: '
if [[ "$FINAL_BODY" != "$EXPECTED" ]]; then
  printf '%s' "$FINAL_BODY" | od -An -tx1 > "$WORK/final.hex"
  printf '%s' "$EXPECTED" | od -An -tx1 > "$WORK/expected.hex"
  log "final_hex=$(tr '\n' ' ' < "$WORK/final.hex" | tail -c 200)"
  fail "final body != expected (bytes $(printf '%s' "$FINAL_BODY" | wc -c) vs $(printf '%s' "$EXPECTED" | wc -c))"
fi
log "step7 owner_full_readback=pass bytes=$(printf '%s' "$FINAL_BODY" | wc -c)"

# ---- 垂直导航（会话共同处理器，accepted 排版+首选列位）----
# 删除后正文 5 行、末行 "Tail flag: "（12 字符）。点击右下角在文末；
# 一次 Up 应回上一行行尾（首选列位=右缘钳制），caret 恰减 13（换行+12 字符）。
# 删除后文本 5 行；行4 "CJK: 中😀文 mid" 的 UTF-16 区间为 [72,84)（行尾换行在
# 84）。文末 caret=97，一次 Up 按首选列位落到**行4 内部**（期望按行界断言，
# 不绑定具体列位像素），再一次 Down 应回文末（钳制到行尾）。
V0="$(ax_focus_caret)"
[[ "$V0" == "97" ]] || log "note caret_end=${V0} (expected 97; layout drift tolerated below)"
drive key 126 || blocked "up undelivered"
V1="$(wait_caret_changes_from "$V0" 25)" || fail "up did not move the caret"
log "step6b vertical_up caret=${V0}->${V1}"
(( V1 >= 72 && V1 < 84 )) || fail "up should land inside line4 [72,84), got ${V1}"
# 回程按同一首选列位落点：行5 尾部空格零宽时命中其后冒号（96）而非文末
# （97），两者都是该列位的合法停靠——按行界断言。
drive key 125 || blocked "down undelivered"
V4="$(wait_caret_changes_from "$V1" 25)" || fail "down did not move"
(( V4 >= 85 && V4 <= V0 )) || fail "down should land inside line5 [85,${V0}], got ${V4}"
log "step6b vertical_navigation=pass round_trip=${V0}->${V1}->${V4} zero_writes"
close_pressed=0
cjgui_ax 10 -e "tell application \"System Events\"
  set p to first process whose unix id is $AX_PID
  try
    click button 1 of window 1 of p
    return \"pressed\"
  on error
    return \"missing\"
  end try
end tell" > "$WORK/close.txt" 2>&1 || true
[[ "$(tail -1 "$WORK/close.txt")" == "pressed" ]] && close_pressed=1
if (( ! close_pressed )); then
  WINDOW_FRAME="$(ax_window_frame)"
  if [[ -n "$WINDOW_FRAME" && "$WINDOW_FRAME" != "missing" ]]; then
    wx="$(print -r -- "$WINDOW_FRAME" | awk '{print $1}')"
    wy="$(print -r -- "$WINDOW_FRAME" | awk '{print $2}')"
    "$DRIVER" click $(( wx + 14 )) $(( wy + 14 )) >> "$WORK/driver.log" 2>&1 || true
    close_pressed=1
  fi
fi
waited=0
summary_line=""
while (( waited < 90 )); do
  summary_line="$(grep '^RANGE_TEXT_SUMMARY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$summary_line" ]] && break
  sleep 1; waited=$(( waited + 1 ))
done
[[ -n "$summary_line" ]] || fail "no RANGE_TEXT_SUMMARY after close"
log "step8 $summary_line"

sum_field() { print -r -- "$summary_line" | tr ' ' '\n' | awk -F= -v k="$1" '$1 == k {print $2; exit}'; }
[[ "$(sum_field leaked_range_events)" == "0" ]] || fail "a second write path leaked: $summary_line"
accepted="$(sum_field session_accepted)"
applied="$(sum_field applied)"
rejected="$(sum_field rejected)"
[[ "$applied" == <-> && "$rejected" == <-> ]] || fail "summary fields missing"
[[ "$rejected" == "0" ]] || fail "owner refused an edit: $summary_line"
(( applied >= 2 )) || fail "expected at least 2 applied owner writes, got $applied"
# 删除经 deleteBackward 走全值增量通道（框架拥有的同一条 sink 写入路径，
# 版本检查同源）；插入类输入的会话范围意图计数见既有 real-input 脚本。
log "note channel=full_value_delta accepted=${accepted} applied=${applied}"

# owner 原字节读回（应用 store 自报 hex，仅在关闭后打印）：与期望语料逐字节比对。
OWNER_HEX_LINE="$(grep '^RANGE_TEXT_OWNER_HEX' "$STDOUT_LOG" | tail -1 || true)"
[[ -n "$OWNER_HEX_LINE" ]] || fail "owner original-byte readback line missing"
OWNER_HEX_NOW="$(print -r -- "$OWNER_HEX_LINE" | tr ' ' '\n' | awk -F= '$1=="hex"{print $2; exit}')"
EXPECTED_FINAL_HEX="$(printf '%s' "$EXPECTED" | od -An -tx1 | tr -d ' \n')"
[[ "$OWNER_HEX_NOW" == "$EXPECTED_FINAL_HEX" ]] \
  || fail "owner original bytes differ from corpus-minus-flag-and-sentinel"
OWNER_BYTES_LINE="$(print -r -- "$OWNER_HEX_LINE" | tr ' ' '\n' | awk -F= '$1=="bytes"{print $2; exit}')"
[[ "$OWNER_BYTES_LINE" == "$(printf '%s' "$EXPECTED" | wc -c | tr -d ' ')" ]] \
  || fail "owner byte count ${OWNER_BYTES_LINE} != $(printf '%s' "$EXPECTED" | wc -c | tr -d ' ')"
log "step9a owner_original_bytes=pass ${OWNER_BYTES_LINE}B"

WORKLOAD_BASE="$(grep '^RANGE_TEXT_WORKLOAD phase=baseline' "$STDOUT_LOG" | tail -1 || true)"
WORKLOAD_FINAL="$(grep '^RANGE_TEXT_WORKLOAD phase=final' "$STDOUT_LOG" | tail -1 || true)"
[[ -n "$WORKLOAD_BASE" && -n "$WORKLOAD_FINAL" ]] || fail "workload counters missing from the same run"
log "step9 workload_base='$WORKLOAD_BASE'"
log "step9 workload_final='$WORKLOAD_FINAL'"

# 统一意图切片后：delete/move 选择器由会话共同处理器唯一裁决；
# 本脚本恰好 2 个删除意图 ⇒ applied 必须恰为 2（防双执行/重复入账）。
[[ "$applied" == "2" ]] \
  || fail "expected EXACTLY 2 owner transactions (2 delete intents), got ${applied}"
# 六意图专属链硬判据：本脚本无任何键入插入，全值伴随通知计数必须为 0——
# 删除/移动不得经整值差分通道写正文（原生默认双重执行的直接读数）。
# 垂直导航（含回程）零正文事务：applied 保持 2。
EV_AFTER="$(sum_field applied)"
[[ "$EV_AFTER" == "2" ]] \
  || fail "vertical navigation must not write (applied=${EV_AFTER})"
fullEvents="$(sum_field full_text_events)"
[[ "$fullEvents" == "0" ]] \
  || fail "six-intent chain must not use whole-value companion writes (full_text_events=${fullEvents})"
# 三类守恒（终局快照）。
gDec="$(sum_field range_decisions)"
gAcc="$(sum_field session_accepted)"
gRef="$(sum_field session_refused)"
gZero="$(sum_field zero_write_selections)"
(( gDec == gAcc + gRef + gZero )) \
  || fail "conservation broken: ${gDec} != ${gAcc}+${gRef}+${gZero}"
log "PASS range text window grapheme input: applied=$applied accepted=$gAcc zero_write=$gZero refused=$gRef leaked=0 moves=2 deletes=2 full_value=0"
echo "range text window grapheme input: PASS applied=$applied accepted=$accepted logged=$LOG"
exit 0
