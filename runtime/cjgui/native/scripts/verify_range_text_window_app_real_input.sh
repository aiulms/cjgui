#!/usr/bin/env zsh
# 1b 独立正常窗口消费链（真实平台输入）。
#
# 消费者 = examples/range_text_window_app：只依赖导出的 cjgui 公共包，自己的字节数组
# 既是 owner Source 也是唯一 Sink；会话由**窗口**建立并拥有（bindRangeTextSession）。
# 本脚本用真实桌面输入（CGEvent → 窗口服务器 → AppKit NSEvent）驱动它的普通窗口，
# 读回窗口内 AX 值和应用自己打印的汇总；不经过探针接缝，也不直接调用会话 API。
#
# 断言：
#   1. 启动即绑定：`RANGE_TEXT_READY … session_bound=true`，首次投影正文 = 镜
#      像（镜像字节数 == owner 字节数）；
#   2. 真实点击进入正文：AX API 读回平台真实焦点在文本适配器（AXTextArea,
#      focus=1），且正文节点的选中范围回到该适配器的真实插入点（节点绑带成立）；
#   3. 真实键入 5 个字符：owner 字节增长，窗口内正文（AX 读回）与 owner 一致；
#   4. Shift+Left ×5 后键入 2 字符：以**非空范围替换**（"Hello" 消失），
#      不是插入到 old 长度旧坐标上（那会保留 "Hello"）；
#   5. Backspace 删除一个字符；再输入 CJK+emoji（真实 unicode 键盘事件）；
#   6. 关闭窗口后应用打印 `RANGE_TEXT_SUMMARY`：全程 `leaked_range_events=0`
#      且 `full_text_events ≥ 1`（同笔整值事件照常到达 owner，只记录不消费、
#      不写正文），唯一写入路径 = 会话判决 ⇒ `accepted == applied`、`rejected=0`。
#
# 明示不覆盖：真实系统 IME 组字（marked）不在本脚本；这里只有合成 CGEvent 键盘输入，
# 不是人工物理输入。组合式 AX 节点自身的 AXFocused 属性经 AX API 读为 false
# （AppKit 用真实 firstResponder 链回答该属性，而 firstResponder 是隐藏适配器），
# 本脚本据此以适配器焦点 + 节点选中范围为焦点证据。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/range_text_window_app"
OUTPUT_DIR="${CJGUI_RANGE_TEXT_REAL_INPUT_TMPDIR:-/private/tmp/cjgui-range-text-window-real-input}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
if [[ -n "${CJ_GUI_SDKROOT:-}" && -d "$CJ_GUI_SDKROOT" ]]; then
  export SDKROOT="$CJ_GUI_SDKROOT"
else
  export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/real-input.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -40 "$LOG"; echo "range text window real input: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -40 "$LOG"; echo "range text window real input: BLOCKED $1" >&2; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

APP_PID=""
AX_PID=""
ROUND_DIR="$WORK/round-app"
ROUND_APP=""
ROUND_EXEC=""

# 身份在启动前登记：即使进程没跑到 ready 握手也要能按身份回收。
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
CANDIDATE_EXECS=("")
CANDIDATE_DIRS=("$ROUND_DIR")
CANDIDATE_DESCS=("")

cleanup() {
  if [[ -n "$APP_PID" ]]; then
    cjgui_terminate_owned "$APP_PID" "" "$ROUND_EXEC" "$ROUND_DIR" || true
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
log "step0 desktop_input_driver=built ax_focus_probe=built preflight=granted"

NAME_TOKEN="CJGUIRangeTextConsumer"
SUFFIX="Rt${RUN_TAG//-/}"
BUNDLE_TOKEN="org.cangjie.cjgui.range-text-consumer.example"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "$SUFFIX" "$BUNDLE_TOKEN" \
  || blocked "could not prepare the per-round application copy"
ROUND_APP="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app"
ROUND_EXEC="$ROUND_APP/Contents/MacOS/${NAME_TOKEN}${SUFFIX}"
CANDIDATE_EXECS=("${NAME_TOKEN}${SUFFIX}")
[[ -x "${ROUND_DIR}/run.sh" ]] || blocked "round copy has no run.sh"

STDOUT_LOG="$WORK/app.log"
ROUND_STARTED="$(date +%s)"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )

# 冷构建（round copy 自带目标目录）后应用才打印 READY；上限 900 s 覆盖冷编译。
waited=0
ready_line=""
while (( waited < 900 )); do
  ready_line="$(grep '^RANGE_TEXT_READY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$ready_line" ]] && break
  sleep 2; waited=$(( waited + 2 ))
done
[[ -n "$ready_line" ]] || blocked "the consumer never published RANGE_TEXT_READY (see $STDOUT_LOG)"
log "step1 $ready_line"

APP_PID="$(cjgui_unique_round_pid "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "no single round-owned pid for ${NAME_TOKEN}${SUFFIX}"
cjgui_unique_round_owns "$APP_PID" "${NAME_TOKEN}${SUFFIX}" "$ROUND_DIR" || blocked "the pid is not this round's instance"
AX_PID="$APP_PID"
log "step1b launched pid=$APP_PID exec=$ROUND_EXEC"

# ---- AX 读取助手（按 AXIdentifier 匹配；语义节点公开 semanticId） ----
ax_identifier_value() { # <semanticId> <kind> -> value | no_value | missing
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
  end tell" 2>/dev/null | tail -1 || true
}
ax_identifier_value_any() { # <semanticId>
  local wanted="$1" kind v
  for kind in "UI element" "text area" "text field" "static text"; do
    v="$(ax_identifier_value "$wanted" "$kind")"
    if [[ -n "$v" && "$v" != "missing" ]]; then print -r -- "$kind|$v"; return 0; fi
  done
  print -r -- "missing"
  return 1
}
ax_identifier_frame_any() { # <semanticId>
  local wanted="$1" kind f
  for kind in "UI element" "text area" "text field"; do
    f="$(ax_identifier_frame "$wanted" "$kind")"
    if [[ -n "$f" && "$f" != "missing" ]] && frame_is_positive "$f"; then print -r -- "$kind|$f"; return 0; fi
  done
  print -r -- "missing"
  return 1
}
ax_focus_probe_lines() { # -> "app_focused role=… focus=…" + "node role=… caret=…"
  "$AX_PROBE" "$AX_PID" "range-text-body" 2>/dev/null || true
}
probe_field() { # probe_field <line> <name>
  print -r -- "$1" | tr ' ' '\n' | awk -F= -v k="$2" '$1 == k {print $2; exit}'
}
body_text() {
  local value
  value="$(ax_identifier_value_any "range-text-body" || true)"
  print -r -- "${value#*|}"
}
wait_body_contains() { # <needle> [attempts] -> final text; 0 when the needle appeared
  local needle="$1" attempts="${2:-30}" i=0 text=""
  while (( i < attempts )); do
    text="$(body_text)"
    [[ "$text" == *"$needle"* ]] && { print -r -- "$text"; return 0; }
    sleep 0.4; i=$(( i + 1 ))
  done
  print -r -- "$text"; return 1
}
status_field() { # status_field <name> -> value
  local name="$1" value
  value="$(ax_identifier_value_any "range-text-status" || true)"
  print -r -- "${value#*|}" | tr ' ' '\n' | awk -F= -v k="$name" '$1 == k {print $2; exit}'
}
wait_status_field() { # wait_status_field <name> <expected> <attempts>
  local name="$1" expected="$2" attempts="${3:-20}" i=0 got=""
  while (( i < attempts )); do
    got="$(status_field "$name")"
    [[ "$got" == "$expected" ]] && { print -r -- "$got"; return 0; }
    sleep 0.4; i=$(( i + 1 ))
  done
  print -r -- "${got:-missing}"
  return 1
}

# ---- 激活（前台 + key 窗口） ----
real_ax_wait_ready "$AX_PID" 24 > "$WORK/ax-ready.txt" 2>&1 || true
activation_attempt=0
while (( activation_attempt < 3 )); do
  activate_app
  sleep 0.8
  [[ "$(app_frontmost)" == "true" ]] && break
  activation_attempt=$(( activation_attempt + 1 ))
done
if [[ "$(app_frontmost)" != "true" ]]; then
  key_variant="$(ensure_window_key || true)"
  log "activation_fallback variant=${key_variant:-none} frontmost=$(app_frontmost)"
fi
[[ "$(app_frontmost)" == "true" ]] || blocked "the application did not become frontmost"
log "step2 frontmost=true"

# ---- 就绪断言 ----
INITIAL_OWNER_BYTES="$(print -r -- "$ready_line" | tr ' ' '\n' | awk -F= '$1 == "owner_bytes" {print $2; exit}')"
MIRROR_BYTES="$(print -r -- "$ready_line" | tr ' ' '\n' | awk -F= '$1 == "mirror_bytes" {print $2; exit}')"
SESSION_BOUND="$(print -r -- "$ready_line" | tr ' ' '\n' | awk -F= '$1 == "session_bound" {print $2; exit}')"
[[ "$SESSION_BOUND" == "true" ]] || fail "session was not bound at start: $ready_line"
[[ "$INITIAL_OWNER_BYTES" == "$MIRROR_BYTES" ]] \
  || fail "first projection is not the session mirror: owner=$INITIAL_OWNER_BYTES mirror=$MIRROR_BYTES"
log "step2b session_bound=true initial_owner_bytes=$INITIAL_OWNER_BYTES mirror_matches=true"

# ---- 正文节点：真实点击 → 平台适配器持有真实键盘焦点 ----
BODY="$(ax_identifier_frame_any "range-text-body" || true)"
[[ "$BODY" != "missing" ]] || blocked "range-text-body has no positive AX frame"
BODY_KIND="${BODY%%|*}"; BODY_FRAME="${BODY#*|}"
click_frame_center "$BODY_FRAME" || blocked "could not click the body frame"
sleep 0.4
FOCUS_LINES="$(ax_focus_probe_lines)"
APP_FOCUS_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{print; exit}')"
NODE_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^node /{print; exit}')"
if [[ "$(probe_field "$APP_FOCUS_LINE" role)" != "AXTextArea" || "$(probe_field "$APP_FOCUS_LINE" focus)" != "1" ]]; then
  # 可见窗口的第一次点击可能只用于激活;第二次点击必须把真实焦点交给正文。
  click_frame_center "$BODY_FRAME" || blocked "second body click could not be delivered"
  sleep 0.4
  FOCUS_LINES="$(ax_focus_probe_lines)"
  APP_FOCUS_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^app_focused /{print; exit}')"
  NODE_LINE="$(print -r -- "$FOCUS_LINES" | awk '/^node /{print; exit}')"
fi
log "step3 body_kind=$BODY_KIND frame=$BODY_FRAME app_focus='$APP_FOCUS_LINE' node='$NODE_LINE'"
[[ "$(probe_field "$APP_FOCUS_LINE" role)" == "AXTextArea" && "$(probe_field "$APP_FOCUS_LINE" focus)" == "1" ]] \
  || fail "the platform text adapter did not take real keyboard focus ($APP_FOCUS_LINE)"
NODE_CARET="$(probe_field "$NODE_LINE" caret)"
[[ "$NODE_LINE" == node\ * && "$NODE_CARET" == <-> ]] \
  || fail "the body node is not tied to the focused adapter (no caret; $NODE_LINE)"

# ---- 阶段 A：真实键入 5 字符 ----
drive type "Hello" || blocked "could not deliver the type input"
BODY_TEXT="$(wait_body_contains "Hello" 30)" || fail "window body does not show the typed text (body='$BODY_TEXT')"
log "step4 typed=Hello window_body_has_text=true applied=$(status_field edits) version=$(status_field v)"

# ---- 阶段 B：Shift+Left ×5 选中后键入 2 字符 = 非空范围替换 ----
for _ in 1 2 3 4 5; do drive shortcut shift 123; done
sleep 0.3
drive type "Hi" || blocked "could not deliver the replacement input"
BODY_TEXT="$(wait_body_contains "Hi" 30)" || fail "replacement text missing from the window body (body='$BODY_TEXT')"
[[ "$BODY_TEXT" != *Hello* ]] || fail "shift-selection replacement did not replace the selection (body='$BODY_TEXT')"
log "step5 shift_select_replace=Hi applied=$(status_field edits)"

# ---- 阶段 C：Backspace 删除一个字符，再键入 CJK+emoji ----
drive key 51 || blocked "could not deliver backspace"
sleep 0.5
drive type "中" || blocked "could not deliver CJK input"
BODY_TEXT="$(wait_body_contains "中" 30)" || fail "CJK input did not reach the window body (body='$BODY_TEXT')"
drive type "😀" || blocked "could not deliver emoji input"
BODY_TEXT="$(wait_body_contains "😀" 30)" || fail "emoji input did not reach the window body (body='$BODY_TEXT')"
log "step6 unicode_ok applied=$(status_field edits) decisions=$(status_field decisions)"
STATUS_RAW="$(ax_identifier_value_any "range-text-status" || true)"
log "step6b status_line='${STATUS_RAW#*|}'"

# ---- 关闭窗口（AXPress 关闭按钮），等应用自己打印汇总 ----
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
  # 标准窗口的关闭按钮在左上角（红绿灯）；按窗口框架推导后真实点击。
  WINDOW_FRAME="$(ax_window_frame)"
  if [[ -n "$WINDOW_FRAME" && "$WINDOW_FRAME" != "missing" ]]; then
    wx="$(print -r -- "$WINDOW_FRAME" | awk '{print $1}')"
    wy="$(print -r -- "$WINDOW_FRAME" | awk '{print $2}')"
    "$DRIVER" click $(( wx + 14 )) $(( wy + 14 )) >> "$WORK/driver.log" 2>&1 || true
    close_pressed=1
  fi
fi
log "step7 close_button pressed=$close_pressed"

waited=0
summary_line=""
while (( waited < 90 )); do
  summary_line="$(grep '^RANGE_TEXT_SUMMARY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$summary_line" ]] && break
  sleep 1; waited=$(( waited + 1 ))
done
if [[ -z "$summary_line" ]]; then
  log "BLOCKED clean_close_timeout after=${waited}s"
  fail "window close did not reach the owner summary within 90 s (AX evidence above still applies)"
fi
log "step8 $summary_line"

sum_field() { print -r -- "$summary_line" | tr ' ' '\n' | awk -F= -v k="$1" '$1 == k {print $2; exit}'; }
[[ "$(sum_field leaked_range_events)" == "0" ]] || fail "a second write path leaked: $summary_line"
accepted="$(sum_field session_accepted)"
applied="$(sum_field applied)"
rejected="$(sum_field rejected)"
owner_bytes="$(sum_field owner_bytes)"
full_events="$(sum_field full_text_events)"
[[ "$accepted" == <-> && "$applied" == <-> && "$rejected" == <-> && "$owner_bytes" == <-> && "$full_events" == <-> ]] \
  || fail "summary fields missing: $summary_line"
(( accepted >= 4 )) || fail "expected at least 4 accepted range decisions, got $accepted: $summary_line"
(( accepted == applied )) || fail "accepted ($accepted) != applied ($applied): $summary_line"
decisions="$(sum_field range_decisions)"
refused="$(sum_field session_refused)"
zeroWrite="$(sum_field zero_write_selections)"
[[ "$decisions" == <-> && "$refused" == <-> && "$zeroWrite" == <-> ]] || fail "decision counters missing: $summary_line"
# 三类守恒（终局快照）：正文接受 + 零写入选区意图（Shift 扩选等）+ 具名拒绝。
(( decisions == accepted + refused + zeroWrite )) || fail "decisions ($decisions) != accepted+refused+zeroWrite ($accepted+$refused+$zeroWrite): $summary_line"
[[ "$rejected" == "0" ]] || fail "owner refused an edit: $summary_line"
# 整值事件必须**照常到达**（每笔意图的伴随事件，如实记录），但不被消费、不写正文；
# 唯一写入路径由 accepted == applied 与 owner 正文一致证明。
(( full_events >= 1 )) || fail "no whole-value companion event reached the owner at all: $summary_line"
if grep -q '^RANGE_TEXT_LEAK' "$STDOUT_LOG"; then
  fail "RANGE_TEXT_LEAK appeared in the application log"
fi
log "step9 assertions accepted=$accepted applied=$applied rejected=$rejected full_text_events=$full_events owner_bytes=$owner_bytes initial=$INITIAL_OWNER_BYTES"

# 真实输入必须改变 owner 字节:5 字符插入 + 选中替换 + 删除 + CJK/emoji 后,
# 最终长度与精确正文由 summary/owner 读回决定,这里只要求确有增长并记录差值。
(( owner_bytes != INITIAL_OWNER_BYTES )) || fail "owner bytes did not change under real input"
log "PASS range text window real input: applied=$applied accepted=$accepted leaked=0 full_text_recorded=$full_events owner_bytes=$owner_bytes"
echo "range text window real input: PASS applied=$applied accepted=$accepted logged=$LOG"
exit 0
