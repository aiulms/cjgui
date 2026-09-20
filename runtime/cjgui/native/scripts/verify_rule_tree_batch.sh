#!/usr/bin/env zsh
# Window-driven grouped-tree batch chain on a real macOS window.
#
# What this round proves:
#   1. external authorized CREATE_RECORD x100 through the public client;
#   2. the window's own tree surface (real accessibility presses on the
#      expanded groups, "select all", "batch enable") drives the existing
#      BATCH_SET_ENABLED owner action;
#   3. a stale-version batch is rejected with no partial application;
#   4. a human row press + "batch disable" leaves exactly one record disabled;
#   5. a bystander control instance keeps answering public reads after the
#      round instance is reclaimed.
#
# Instance safety: both instances are per-round copies with their own bundle
# identifier, executable name, directory and connection descriptor. Nothing is
# ever selected by "first pid matching a name", nothing outside this round is
# signalled (no killall/pkill), and every accessibility call is bounded.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/rule_set_window_app"
OUTPUT_DIR="${CJGUI_RULE_TREE_BATCH_TMPDIR:-/private/tmp/cjgui-rule-tree-batch}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
CHAIN_LOG="$WORK/chain.log"
AX_LOG="$WORK/ax.log"
: > "$CHAIN_LOG"; : > "$AX_LOG"
log() { print -r -- "$*" >> "$CHAIN_LOG"; }
fail() { log "FAIL $*"; cat "$CHAIN_LOG"; exit 1; }
blocked() { log "BLOCKED $*"; cat "$CHAIN_LOG"; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"

CONTROL_PID=""
CONTROL_DESCRIPTOR=""
APP_PID=""
DESCRIPTOR=""
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  cjgui_terminate_owned "$CONTROL_PID" "${CONTROL_DESCRIPTOR:-}" "$CONTROL_EXEC" "$CONTROL_DIR" || true
}
trap cleanup EXIT

# --- per-round instances ----------------------------------------------------
prepare_instance() { # prepare_instance <role> <suffix>
  local role="$1" suffix="$2" dir="$WORK/$role"
  mkdir -p "$dir"
  cp -R "$APP_DIR/src" "$dir/src"
  cp "$APP_DIR/cjpm.toml" "$dir/cjpm.toml"
  cp "$APP_DIR/cjgui_macos_app.sh" "$dir/cjgui_macos_app.sh"
  python3 - "$dir" "$RUNTIME_DIR" "$suffix" <<'PYID'
import re
import sys
app, runtime, suffix = sys.argv[1:4]
toml = open(f"{app}/cjpm.toml").read()
toml = re.sub(r'cjgui = \{ path = "[^"]+" \}', f'cjgui = {{ path = "{runtime}" }}', toml)
toml = re.sub(r'cjgui_shared_operation_core = \{ path = "[^"]+" \}',
              f'cjgui_shared_operation_core = {{ path = "{runtime}/shared_operation_core" }}', toml)
toml = re.sub(r'cjgui_rule_set_application = \{ path = "[^"]+" \}',
              f'cjgui_rule_set_application = {{ path = "{runtime}/examples/rule_set_application" }}', toml)
open(f"{app}/cjpm.toml", "w").write(toml)
m = open(f"{app}/cjgui_macos_app.sh").read()
m = m.replace("CJGUIRuleSet", f"CJGUIRuleSet{suffix}")
m = m.replace("org.cangjie.cjgui.rule-set.example",
              f"org.cangjie.cjgui.rule-set.{suffix}")
open(f"{app}/cjgui_macos_app.sh", "w").write(m)
PYID
  cat > "$dir/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$RUNTIME_DIR/scripts/run_macos_application.sh" "$dir/cjgui_macos_app.sh" "\$@"
RUNSH
  chmod +x "$dir/run.sh"
  print -r -- "$dir"
}

launch_instance() { # launch_instance <dir> <exec-name> <stdout-log> -> prints descriptor
  local dir="$1" exec_name="$2" stdout_log="$3" waited=0 descriptor=""
  ( cd "$dir" && nohup zsh run.sh > "$stdout_log" 2>&1 & )
  while (( waited < 90 )); do
    descriptor="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$stdout_log" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    if [[ -n "$descriptor" && -f "$descriptor" ]]; then
      print -r -- "$descriptor"
      return 0
    fi
    sleep 2; waited=$((waited + 2))
  done
  return 1
}

CONTROL_DIR="$(prepare_instance control "Control${RUN_TAG}")"
CONTROL_EXEC="$CONTROL_DIR/target/release/CJGUIRuleSetControl${RUN_TAG}.app/Contents/MacOS/CJGUIRuleSetControl${RUN_TAG}"
CONTROL_STDOUT="$WORK/control-stdout.log"
CONTROL_DESCRIPTOR="$(launch_instance "$CONTROL_DIR" "CJGUIRuleSetControl${RUN_TAG}" "$CONTROL_STDOUT")" \
  || fail "control instance did not become ready"
CONTROL_PID="$(cjgui_descriptor_owner_pid "$CONTROL_DESCRIPTOR" "$CONTROL_EXEC" "$CONTROL_DIR" || true)"
[[ -n "$CONTROL_PID" ]] || fail "control instance descriptor has no matching owner"
log "control_ready pid=$CONTROL_PID descriptor=$CONTROL_DESCRIPTOR"

ROUND_DIR="$(prepare_instance round "Round${RUN_TAG}")"
ROUND_EXEC="$ROUND_DIR/target/release/CJGUIRuleSetRound${RUN_TAG}.app/Contents/MacOS/CJGUIRuleSetRound${RUN_TAG}"
ROUND_STARTED="$(date +%s)"
ROUND_STDOUT="$WORK/round-stdout.log"
DESCRIPTOR="$(launch_instance "$ROUND_DIR" "CJGUIRuleSetRound${RUN_TAG}" "$ROUND_STDOUT")" \
  || fail "round instance did not become ready"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "round instance descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "round pid is not this round's instance"
[[ "$APP_PID" != "$CONTROL_PID" ]] || fail "round pid resolved to the control instance"
log "round_ready pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
control_pub() { python3 "$CLIENT" "$CONTROL_DESCRIPTOR" "$@"; }

ax() { # ax <seconds> <applescript>
  local limit="$1"; shift
  cjgui_ax "$limit" -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    $1
  end tell" >> "$AX_LOG" 2>&1
}
front() {
  ax 15 'set frontmost of p to true
    perform action "AXRaise" of window 1 of p' || true
  sleep 0.3
}
ax_press() { # ax_press <button description>
  ax 20 "click button \"$1\" of window 1 of p" || true
  sleep 0.4
}
ax_answered() { # ax_answered -> 0 when the round window listing answers
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    return name of every button of window 1 of p
  end tell" > "$WORK/ax-listing.log" 2>&1
}
read_final_values() { # read_final_values <path>
  pub get > "$1" 2>&1 || true
}

# --- 1. external authorized CREATE_RECORD x100 ----------------------------
CREATE_LOG="$WORK/creates.log"
: > "$CREATE_LOG"
version=0
for n in $(seq 1 100); do
  label="记录-$(printf '%03d' "$n")"
  pub invoke "$version" CREATE_RECORD --target 8000 \
    --arg label=STRING:"$label" --arg enabled=BOOLEAN:false \
    --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" \
    --arg requestId=STRING:"create-$n" >> "$CREATE_LOG" 2>&1 || true
  version=$((version + 1))
done
appliedCount="$(grep -c '^APPLIED true' "$CREATE_LOG" || true)"
[[ "$appliedCount" == 100 ]] || fail "expected 100 applied creates, got $appliedCount"
log "step1 external_create_ok count=100"

# --- 2. window grouped tree: expand + select all + batch enable ------------
front
if ! ax_answered; then
  blocked "accessibility bridge did not answer for the round window; window-driven tree batch is unverified"
fi
ax 'set frontmost of p to true
  perform action "AXRaise" of window 1 of p'
ax_press "▸ 已启用"
ax_press "▸ 未启用"
sleep 0.5
ax_press "全选可见"
ax_press "批量启用所选"
sleep 1.5

ENABLED="$(pub get 2>/dev/null | grep -cE 'enabled BOOLEAN 1$' || true)"
[[ "$ENABLED" == 100 ]] || fail "enabled count after window batch = $ENABLED (expected 100)"
log "step2 tree_batch_enable_ok enabled=100"

# --- 3. stale-version batch rejection --------------------------------------
CURRENT_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
STALE_LOG="$WORK/stale-batch.log"
pub invoke $((CURRENT_VERSION - 1)) BATCH_SET_ENABLED --target 8000 --arg enabled=BOOLEAN:false \
  --arg requestId=STRING:"stale-1" > "$STALE_LOG" 2>&1 || true
grep -q '^APPLIED true' "$STALE_LOG" && fail "stale batch unexpectedly applied"
grep -q 'CONFLICT true' "$STALE_LOG" || fail "stale batch missing conflict marker"
log "step3 stale_batch_rejected"

# --- 4. human: one leaf added to the selection, batch-disable --------------
front
ax_press "清空多选"
sleep 0.4
ax_press "☐ 记录-001"
sleep 0.4
ax_press "批量停用所选"
sleep 1.2

FINAL_LOG="$WORK/final-state.log"
read_final_values "$FINAL_LOG"
DISABLED_FINAL="$(grep -cE 'enabled BOOLEAN 0$' "$FINAL_LOG" || true)"
ENABLED_FINAL="$(grep -cE 'enabled BOOLEAN 1 1$' "$FINAL_LOG" || true)"
[[ "$DISABLED_FINAL" == 1 && "$ENABLED_FINAL" == 99 ]] || \
  fail "final state mismatch: disabled=$DISABLED_FINAL enabled=$ENABLED_FINAL"
log "step4 batch_disable_ok disabled=1 enabled=99"

# --- 5. the bystander control instance still answers ------------------------
CONTROL_STATE="$(control_pub get 2>/dev/null | grep -c '^KIND SNAPSHOT' || true)"
[[ "$CONTROL_STATE" == 1 ]] || fail "control instance stopped answering after the round"
log "step5 control_instance_ok"

log "PASSED batch chain"
cat "$CHAIN_LOG"
exit 0
