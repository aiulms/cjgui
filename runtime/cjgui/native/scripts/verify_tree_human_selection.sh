#!/usr/bin/env zsh
# Human tree interaction reflected through the shared selection entry.
#
# The human presses a real row/group button in the window (AX action); the
# same selection object the window uses must then be readable through the
# public connection with exact stable keys, focus and anchor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_TREE_HUMAN_TMPDIR:-/private/tmp/cjgui-tree-human}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

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

APP_EXE="$APP_DIR/target/release/CJGUIRuleSet.app/Contents/MacOS/CJGUIRuleSet"
APP_PID=""
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

# A locked session exposes no AX window for the rule tree, so the expand /
# select-all presses below select nothing and the chain would report a product
# FAILure ("selected 0 keys"). Report the measured lock as BLOCKED (exit 3);
# the sweep classifies exit 3 as BLOCKED.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "tree human selection chain: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); the AX expand/select-all presses cannot be delivered" >&2
  exit 3
fi
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$APP_EXE" "$APP_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$APP_EXE" "$APP_DIR" && echo no || echo yes)"
}
trap cleanup EXIT

ROUND_STARTED="$(date +%s)"
STDOUT_LOG="$WORK/app.log"
( cd "$APP_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
DESCRIPTOR=""
waited=0
while (( waited < 120 )); do
  DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$STDOUT_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]]; then break; fi
  sleep 2; waited=$((waited + 2))
done
[[ -f "$DESCRIPTOR" ]] || fail "app did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$APP_EXE" "$APP_DIR" || true)"
[[ -n "$APP_PID" ]] || fail "app descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$APP_EXE" "$APP_DIR" || fail "app pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
selection_keys() { pub tree-selection 2>/dev/null | awk '/^KEY /{print $2}' | sort; }
selection_focus() { pub tree-selection 2>/dev/null | awk '/^FOCUS /{print $2}'; }
selection_version() { pub tree-selection 2>/dev/null | awk '/^SELECTION_VERSION /{print $2}'; }
selections_count() { pub tree-selection 2>/dev/null | grep -c '^KEY ' || true; }

ax_press_optional() { # ax_press_optional <description>
  if osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
    click button \"$1\" of window 1 of p
    return \"ok\"
  end tell" > "$WORK/ax.log" 2>&1; then
    sleep 1
    return 0
  fi
  return 1
}

ax_press() { # ax_press <description>
  osascript -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
    click button \"$1\" of window 1 of p
  end tell" > "$WORK/ax.log" 2>&1 || true
  sleep 1
}

# --- records -----------------------------------------------------------------
version=0
for n in 1 2 3; do
  pub invoke "$version" CREATE_RECORD --target 8000 --arg label=STRING:"人工记录$n" \
    --arg enabled=BOOLEAN:true --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"tree-human-$n" > /dev/null 2>&1 || true
  version=$((version + 1))
done
[[ "$(pub get 2>/dev/null | grep -cE '^FIELD [0-9]+ label STRING')" == 3 ]] || fail "records were not created"
log "step1 records_ready count=3"

# --- human expands the group -------------------------------------------------
V_BEFORE="$(selection_version)"
ax_press "▸ 已启用"
V_AFTER_EXPAND="$(selection_version)"
[[ "$V_AFTER_EXPAND" == "$V_BEFORE" ]] || fail "expanding a group should not change the selection version"
PROJECTION_AFTER="$(pub tree-selection 2>/dev/null | awk '/^PROJECTION_VERSION /{print $2}')"
log "step2 human_expand_ok projection_version=$PROJECTION_AFTER"

# --- human selects through the section's own button -------------------------
# The human group press above must have expanded the projection; the section's
# select-all button then selects exactly the rows the human can see.
ax_press "全选可见"
COUNT="$(selections_count)"
KEYS_AFTER="$(selection_keys | tr '\n' ' ')"
[[ "$COUNT" == 3 ]] || fail "human expand+select-all selected $COUNT keys (want 3)"
[[ "$KEYS_AFTER" == *"record-1"* && "$KEYS_AFTER" == *"record-3"* ]] || fail "keys missing: '$KEYS_AFTER'"
log "step3 human_expand_select_all_ok keys=$COUNT"

# --- human presses a real expanded leaf row ---------------------------------
# The accessibility projection is the human click surface: once the human
# expanded the group above, the leaf row button must be exposed and pressing it
# must drive the same selection entry the shared command uses. A bridge failure
# is an environment note; a listing that answers without the row is a defect.
AX_NAMES_LOG="$WORK/ax-names.log"
AX_LISTING="no"
attempt=0
while (( attempt < 4 )); do
  if cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    return name of every button of window 1 of p
  end tell" > "$AX_NAMES_LOG" 2>&1; then
    AX_LISTING="yes"
    grep -q "人工记录1" "$AX_NAMES_LOG" && break
  fi
  # Bounded call; a degraded bridge is a tool limitation recorded as a note,
  # never repaired by restarting System Events.
  sleep 2
  attempt=$((attempt + 1))
done
if [[ "$AX_LISTING" == "yes" ]]; then
  grep -q "人工记录1" "$AX_NAMES_LOG" || fail "accessibility tree lists buttons but not the expanded leaf row"
  ax_press "☐ 人工记录1"
  COUNT_ROW="$(selections_count)"
  KEYS_ROW="$(selection_keys | tr '\n' ' ')"
  [[ "$COUNT_ROW" == 1 ]] || fail "plain human row click selected $COUNT_ROW keys"
  [[ "$KEYS_ROW" == *"record-1"* ]] || fail "human row click did not select record-1 (got '$KEYS_ROW')"
  log "step4 human_row_click_ok key=record-1"
else
  log "note ax_bridge_unavailable_after=${attempt} (bounded; row click covered by the shared selection command, not claimed as human input)"
fi

if [[ "$AX_LISTING" == "yes" ]]; then
  log "PASSED tree human selection chain"
  cat "$LOG"
  exit 0
fi
# The one assertion that needs the accessibility bridge never ran: report it as
# BLOCKED with the concrete reason instead of a green summary.
log "BLOCKED accessibility bridge did not answer within 4 bounded attempts; the human row click is unverified"
cat "$LOG"
exit 3
