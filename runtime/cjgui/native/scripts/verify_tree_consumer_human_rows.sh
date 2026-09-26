#!/usr/bin/env zsh
# Human interaction with the independent UI-only tree consumer: row clicks in
# two different branches, select-all, and collapse keeping the selection. All
# read back through the window's own status text (no connection, no controller
# shortcut).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/tree_outline_consumer"
OUTPUT_DIR="${CJGUI_TREE_CONSUMER_TMPDIR:-/private/tmp/cjgui-tree-consumer-human}"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; exit 1; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

# A locked session exposes no AX window for this bundle, so every row and
# select-all press below would be recorded as a product FAILure although
# nothing was delivered. Report the measured lock as BLOCKED (exit 3) instead;
# the sweep classifies exit 3 as BLOCKED.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "tree consumer human chain: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); the AX row/select-all presses cannot be delivered" >&2
  exit 3
fi

# --- per-round instance -----------------------------------------------------
# This consumer has no connection descriptor, so identity is the round-unique
# bundle/executable name plus the per-round directory: a shared name can never
# select a user instance, and cleanup re-proves ownership before signalling.
NAME_TOKEN="CJGUIUiOnlyStarter"
BUNDLE_TOKEN="org.example.cjgui.ui-only-starter"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Rows${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC_NAME="${NAME_TOKEN}Rows${RUN_TAG}"
APP_PID=""
cleanup() {
  if cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR"; then
    kill "$APP_PID" 2>/dev/null || true
    sleep 1
    cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" && kill -9 "$APP_PID" 2>/dev/null || true
  fi
  log "cleanup: instance closed=$(cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" && echo no || echo yes)"
}
trap cleanup EXIT

STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
waited=0
while (( waited < 150 )); do
  APP_PID="$(cjgui_unique_round_pid "$ROUND_EXEC_NAME" "$ROUND_DIR" || true)"
  if [[ -n "$APP_PID" ]] && grep -q 'TREE_OUTLINE_CONSUMER_READY' "$STDOUT_LOG" 2>/dev/null; then break; fi
  sleep 2; waited=$((waited + 2))
done
[[ -n "$APP_PID" ]] || fail "consumer did not start"
cjgui_unique_round_owns "$APP_PID" "$ROUND_EXEC_NAME" "$ROUND_DIR" || fail "consumer pid is not this round's instance"
log "launched pid=$APP_PID exec=$ROUND_EXEC_NAME owner_verified=unique-exec+dir"

AX_PID="$APP_PID"
AX_APP_PATH="$ROUND_DIR/target/release/${ROUND_EXEC_NAME}.app"
show_page() { # catalog | rows
  local press
  press="$(real_ax_press_identifier "$APP_PID" "catalog-workspace-tab-$1")"
  [[ "$press" == "identifier_press_sent" ]]
}
ax_press() { # <description>
  local page="catalog"
  [[ "$1" == "○ 条目"* ]] && page="rows"
  show_page "$page" || return 1
  if cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
    click button \"$1\" of window 1 of p
    return \"ok\"
  end tell" > "$WORK/ax.log" 2>&1; then
    sleep 1
    return 0
  fi
  sleep 1
  return 1
}
status_text() {
  # Status belongs to the catalog page; a row press occurs on the sibling page.
  show_page catalog || return 1
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set out to \"\"
    repeat with t in (every static text of window 1 of p)
      set v to value of t
      if v contains \"多选\" then set out to v
    end repeat
    return out
  end tell" 2>/dev/null | tail -1
}
selected_count() {
  print -r -- "$(status_text)" | sed -n 's/.*多选 \([0-9]*\) 条.*/\1/p'
}
visible_rows() {
  print -r -- "$(status_text)" | sed -n 's/.*可见 \([0-9]*\) 行.*/\1/p'
}

# --- expand all --------------------------------------------------------------
ax_press "展开全部" || fail "expand-all press failed"
ROWS="$(visible_rows)"
[[ "$ROWS" == "39" ]] || fail "expected 39 visible rows after expand, got '$ROWS'"
log "step1 expand_ok rows=$ROWS"

# --- human row clicks in two different branches ------------------------------
ax_press "○ 条目 0.0.1" || fail "first branch row press failed"
[[ "$(selected_count)" == "1" ]] || fail "first row click selected '$(selected_count)' rows"
log "step2 branch_a_row_click_ok selected=1"

ax_press "○ 条目 0.1.2" || fail "second branch row press failed"
[[ "$(selected_count)" == "1" ]] || fail "second row click replaced wrongly: '$(selected_count)' rows"
log "step3 branch_b_row_click_ok selected=1"

# --- select all entries ------------------------------------------------------
ax_press "全选条目" || fail "select-all press failed"
COUNT="$(selected_count)"
[[ "$COUNT" == "27" ]] || fail "select-all selected $COUNT entries (want 27)"
log "step4 select_all_ok selected=$COUNT"

# --- collapse keeps the logical selection -----------------------------------
ax_press "收起全部" || fail "collapse-all press failed"
ROWS_AFTER="$(visible_rows)"
COUNT_AFTER="$(selected_count)"
[[ "$ROWS_AFTER" == "3" ]] || fail "collapse did not reduce visible rows (got '$ROWS_AFTER')"
[[ "$COUNT_AFTER" == "27" ]] || fail "collapse dropped the logical selection (got '$COUNT_AFTER')"
log "step5 collapse_keeps_selection_ok rows=$ROWS_AFTER selected=$COUNT_AFTER"

log "PASSED tree consumer human chain"
cat "$LOG"
exit 0
