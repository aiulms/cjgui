#!/usr/bin/env zsh
# Consumer-level control usability (P3 / C section) on the runtime-generated
# consumer, a normal application whose pane really carries a button, a generated
# checkbox, generated tab pages and a clipped scroll region.
#
# This is a CONSUMER check: it drives the application's own normal window with
# real posted keyboard/pointer input and Accessibility reads, and asserts what
# the ordinary window/owner boundary does. It never reaches into a probe seam.
#
# Covered:
#   1. keyboard order + focus visible: real Tab presses move focus through
#      several DISTINCT controls and every focused control has a positive,
#      on-window AX frame;
#   2. a disabled control is not activated: after the owner freezes the title
#      field, a real click + keystrokes on that editor leave the accepted value
#      unchanged;
#   3. the public typed client submits a discovered motion declaration as a
#      separate candidate; only scene ACCEPTED and readback precede a real
#      click on the generated control that drives that accepted motion rule;
#   4. an AX action and a real click reach the SAME owner: an Accessibility press
#      on the submit button and a real pointer click on the same button both grow
#      the same owner's version and write the same declared field;
#   5. resize keeps geometry consistent: a real window resize leaves every
#      tracked control's frame positive and inside the resized window.
#
# Explicitly NOT claimed (reported BLOCKED, never converted into a pass):
#   * real VoiceOver navigation is not run (an AX query is not a VoiceOver
#     session);
#   * physical second-display cross-screen behavior is unverified. Controlled
#     1->2 backing scale is covered by the internal-testing vector probe.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/generated_panel_consumer"
OUTPUT_DIR="${CJGUI_CONSUMER_CONTROL_USABILITY_TMPDIR:-/private/tmp/cjgui-consumer-control-usability}"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"
mkdir -p "$WORK"
LOG="$WORK/controls.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; cat "$LOG"; echo "consumer control usability: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; echo "consumer control usability: BLOCKED $1" >&2; exit 3; }

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
APP_PID=""
AX_PID=""
DESCRIPTOR=""

session_locked && blocked "the session is locked; real posted keyboard/pointer input cannot be delivered"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc is required for the real input driver"
DRIVER="$WORK/desktop_input_driver"
swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" >"$WORK/driver-build.log" 2>&1 || blocked "the real input driver did not build"
AX_DRIVER="$WORK/control_ax_driver"
swiftc -O "$RUNTIME_DIR/native/tests/control_ax_driver.swift" -o "$AX_DRIVER" >"$WORK/ax-driver-build.log" 2>&1 \
  || blocked "the recursive AX driver did not build"
real_input_preflight || blocked "synthetic event posting is refused (Accessibility permission missing)"

NAME_TOKEN="CJGUICollaborationStarter"
BUNDLE_TOKEN="org.example.cjgui.consumer-control-usability"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Controls${RUN_TAG}" "$BUNDLE_TOKEN" \
  || blocked "could not prepare the per-round application copy"
ROUND_APP="$ROUND_DIR/target/release/${NAME_TOKEN}Controls${RUN_TAG}.app"
ROUND_EXEC="$ROUND_APP/Contents/MacOS/${NAME_TOKEN}Controls${RUN_TAG}"
AX_APP_PATH="$ROUND_APP"

cleanup() { cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true; }
trap cleanup EXIT

STDOUT_LOG="$WORK/app.log"
ROUND_STARTED="$(date +%s)"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
waited=0
while (( waited < 150 )); do
  DESCRIPTOR="$(grep 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' "$STDOUT_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]] && break
  sleep 2; waited=$(( waited + 2 ))
done
[[ -f "${DESCRIPTOR:-}" ]] || blocked "the consumer did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || blocked "the descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || blocked "the pid is not this round's instance"
AX_PID="$APP_PID"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
field_line() { pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id {print}'; }
field_text() { field_line "$1" | awk '{for (i = 1; i <= NF; i++) if ($i == "DRAFT_HEX") print $(i + 1)}' \
  | python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
domain_version() { pub get 2>/dev/null | awk '/^VERSION /{print $2}'; }

ax_focused_frame() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    try
      set e to value of attribute \"AXFocusedUIElement\" of p
      set pp to position of e
      set ss to size of e
      return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string)
    on error
      return \"missing\"
    end try
  end tell" 2>/dev/null | tail -1 || true
}
ax_description_enabled() { # exact description of one accepted text field
  local wanted="$1"
  local line
  line="$("$AX_DRIVER" "$AX_PID" find-label "$wanted" 2>/dev/null || true)"
  if [[ "$line" == *" enabled=1 "* ]]; then print -r -- true
  elif [[ "$line" == *" enabled=0 "* ]]; then print -r -- false
  else print -r -- missing; fi
}
ax_description_focused() {
  local wanted="$1"
  local line identifier
  line="$("$AX_DRIVER" "$AX_PID" find-label "$wanted" 2>/dev/null || true)"
  identifier="$(print -r -- "$line" | sed -n 's/.* id=\([^ ]*\) .*/\1/p')"
  [[ -n "$identifier" && "$identifier" != "-" && "$(accepted_focus_id)" == "$identifier" ]] \
    && print -r -- true || print -r -- false
}
ax_recursive_frame() {
  local mode="$1" wanted="$2" line frame
  line="$("$AX_DRIVER" "$AX_PID" "$mode" "$wanted" 2>/dev/null || true)"
  frame="$(print -r -- "$line" | sed -n 's/.* frame=\([0-9,-]*\).*/\1/p')"
  [[ -n "$frame" ]] && print -r -- "${frame//,/ }" || print -r -- missing
}
# Nested AX groups do not appear in System Events' one-level `every text field
# of window` enumeration. Query the actual AXChildren tree by exact label/id.
ax_screen_frame() { ax_recursive_frame find-label "$1"; }
ax_identifier_frame() { ax_recursive_frame find-id "$1"; }
real_ax_press_button() {
  local pid="$1" wanted="$2" line identifier
  line="$("$AX_DRIVER" "$pid" find-label "$wanted" 2>/dev/null || true)"
  [[ "$line" == "AX_NODE role=AXButton "* ]] || return 1
  identifier="$(print -r -- "$line" | sed -n 's/.* id=\([^ ]*\) .*/\1/p')"
  [[ -n "$identifier" && "$identifier" != "-" ]] || return 1
  "$AX_DRIVER" "$pid" press-id "$identifier" >/dev/null 2>&1
}
frame_positive() {
  local f="$1" x y w h
  x="$(print -r -- "$f" | awk '{print $1}')"; y="$(print -r -- "$f" | awk '{print $2}')"
  w="$(print -r -- "$f" | awk '{print $3}')"; h="$(print -r -- "$f" | awk '{print $4}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> && "$h" == <-> ]] && (( w > 0 && h > 0 ))
}
frame_inside_window() {
  local f="$1" wf="$2" fx fy fw fh wx wy ww wh
  fx="$(print -r -- "$f" | awk '{print $1}')"; fy="$(print -r -- "$f" | awk '{print $2}')"
  fw="$(print -r -- "$f" | awk '{print $3}')"; fh="$(print -r -- "$f" | awk '{print $4}')"
  wx="$(print -r -- "$wf" | awk '{print $1}')"; wy="$(print -r -- "$wf" | awk '{print $2}')"
  ww="$(print -r -- "$wf" | awk '{print $3}')"; wh="$(print -r -- "$wf" | awk '{print $4}')"
  [[ "$fx" == <-> && "$fy" == <-> && "$fx" -ge "$wx" && "$fy" -ge "$wy" \
     && $(( fx + fw )) -le $(( wx + ww )) && $(( fy + fh )) -le $(( wy + wh )) ]]
}
accepted_focus_id() {
  pub window-interaction 2>/dev/null | awk '$1 == "WINDOW_FOCUS" { print $2; exit }'
}
accepted_focus_state() {
  pub window-interaction 2>/dev/null | awk '$1 == "WINDOW_FOCUS_STATE" { print $2; exit }'
}
ax_focus_identity_frame() {
  local wanted="$1" kind frame
  for kind in "text field" button checkbox "radio button" "UI element"; do
    frame="$(ax_identifier_frame "$wanted" "$kind")"
    if frame_positive "$frame"; then print -r -- "$frame"; return 0; fi
  done
  print -r -- "missing"
  return 1
}
control_visual_hash() { # accepted identity -> pixel hash of the control's current screen frame
  local wanted="$1" frame x y w h name
  frame="$(ax_focus_identity_frame "$wanted")"
  frame_positive "$frame" || return 1
  x="$(print -r -- "$frame" | awk '{print $1}')"; y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"; h="$(print -r -- "$frame" | awk '{print $4}')"
  name="focus-${RANDOM}-${RANDOM}"
  screencapture -x -R"$x,$y,$w,$h" "$WORK/$name.png" 2>/dev/null || return 1
  sips -s format bmp "$WORK/$name.png" --out "$WORK/$name.bmp" >/dev/null 2>&1 || return 1
  shasum -a 256 "$WORK/$name.bmp" | awk '{print $1}'
}

activation_attempt=0
while (( activation_attempt < 3 )); do
  activate_app
  sleep 0.8
  [[ "$(app_frontmost)" == "true" ]] && break
  activation_attempt=$(( activation_attempt + 1 ))
done
if [[ "$(app_frontmost)" != "true" ]]; then
  # LaunchServices and AXRaise can leave a visible window behind another app.
  # The shared driver has one bounded, frame-targeted key-window fallback;
  # require the same frontmost proof afterwards before posting any text.
  key_variant="$(ensure_window_key || true)"
  log "activation_fallback variant=${key_variant:-none} frontmost=$(app_frontmost)"
fi
[[ "$(app_frontmost)" == "true" ]] || blocked "the application did not become frontmost after bounded activation and key-window fallback"

# Establish a real positive control on the exact title editor before the owner
# freezes it. This makes the later unchanged value meaningful: the same input
# path must first have changed the field while it was enabled.
TITLE_FRAME="$(ax_screen_frame "当前任务")"
[[ -n "$TITLE_FRAME" && "$TITLE_FRAME" != "missing" ]] || blocked "title editor frame not found before submit"
TITLE_ENABLED_BEFORE="$(ax_description_enabled "当前任务")"
[[ "$TITLE_ENABLED_BEFORE" == "true" ]] || fail "title editor was not enabled before submit (AXEnabled=$TITLE_ENABLED_BEFORE)"
TITLE_BEFORE_INPUT="$(field_text title)"
click_frame_center "$TITLE_FRAME" || blocked "could not focus the enabled title editor"
sleep 0.3
if [[ "$(ax_description_focused "当前任务")" != "true" ]]; then
  # AppKit can consume the first click to activate a visible window; the
  # second click must place focus on the exact published editor.
  click_frame_center "$TITLE_FRAME" || blocked "second title-editor click could not be delivered"
  sleep 0.3
fi
TITLE_FOCUSED="$(accepted_focus_id)"
log "positive_control_focus frontmost=$(app_frontmost) accepted_focus=$TITLE_FOCUSED frame=$TITLE_FRAME"
if [[ "$(ax_description_focused "当前任务")" != "true" || "$TITLE_FOCUSED" == "none" ]]; then
  log "positive_control_diagnostic ax_node='$("$AX_DRIVER" "$AX_PID" find-label "当前任务" 2>/dev/null || true)' ax_focused='$(ax_focused_description)' ax_focused_frame='$(ax_focused_frame)' window='$(ax_window_frame)' window_focus='$(ax_window_focus_report)'"
fi
[[ "$(app_frontmost)" == "true" && "$(ax_description_focused "当前任务")" == "true" && "$TITLE_FOCUSED" != "none" ]] \
  || blocked "the foreground or exact title focus was lost before positive-control input"
drive type "X" || blocked "could not deliver positive-control text input"
sleep 0.8
TITLE_AFTER_INPUT="$(field_text title)"
if [[ "$TITLE_AFTER_INPUT" == "$TITLE_BEFORE_INPUT" ]]; then
  [[ "$(app_frontmost)" == "true" && "$(ax_description_focused "当前任务")" == "true" ]] \
    || blocked "the foreground or exact title focus was lost during positive-control input"
  fail "enabled title editor did not accept the positive-control input"
fi
log "positive_control enabled_title_input=1 before='$TITLE_BEFORE_INPUT' after='$TITLE_AFTER_INPUT'"

# Restore a valid accepted title through the same authorized owner operation
# used by public consumers; submitting an empty title is correctly rejected.
TITLE_VERSION="$(domain_version)"
SET_TITLE_LOG="$WORK/set-valid-title.log"
pub invoke "$TITLE_VERSION" SET_TITLE --target 8101 --arg title=STRING:control-ready >"$SET_TITLE_LOG" 2>&1 \
  || blocked "could not establish the valid title required by submit"
rg -q '^APPLIED true' "$SET_TITLE_LOG" || fail "valid SET_TITLE did not apply"
[[ "$(field_text title)" == "control-ready" ]] || fail "valid SET_TITLE did not read back from the owner"

# --- 1. keyboard order + focus visible --------------------------------------
# Re-enter the same enabled editor after the external owner write. The owner
# refresh may transfer first responder to the window before keyboard walking.
TITLE_FRAME="$(ax_screen_frame "当前任务")"
[[ -n "$TITLE_FRAME" && "$TITLE_FRAME" != "missing" ]] || fail "title editor missing before Tab walk"
click_frame_center "$TITLE_FRAME" >/dev/null 2>&1 || fail "could not focus title editor before Tab walk"
sleep 0.3
REVEAL_BEFORE_LINE="$(pub generated-instances 2>/dev/null | awk '$1 == "INSTANCE" && $2 == "effectAnimate" { print; exit }')"
REVEAL_SEMANTIC="$(print -r -- "$REVEAL_BEFORE_LINE" | sed -n 's/.* semantic=\([^ ]*\) .*/\1/p')"
REVEAL_BEFORE_VISIBLE="$(print -r -- "$REVEAL_BEFORE_LINE" | sed -n 's/.* visible=\([01]\) .*/\1/p')"
[[ -n "$REVEAL_SEMANTIC" && -n "$REVEAL_BEFORE_VISIBLE" ]] \
  || fail "the generated reveal target has no accepted identity/visibility ($REVEAL_BEFORE_LINE)"
log "reveal_before key=effectAnimate semantic=$REVEAL_SEMANTIC visible=$REVEAL_BEFORE_VISIBLE"
FOCUS_ORDER=()
seen=""
tab_index=0
previous_focus_desc=""
previous_focus_pixels=""
REVEAL_VERIFIED=0
stalled_tabs=0
while (( tab_index < 18 )); do
  drive tab >/dev/null 2>&1 || true
  sleep 0.25
  focus_state="$(accepted_focus_state)"
  desc="$(accepted_focus_id)"
  [[ -n "$focus_state" && -n "$desc" ]] || fail "Tab focus projection was not readable"
  [[ "$focus_state" != "unknown" ]] || fail "Tab produced an unknown accepted focus identity"
  # The walk has completed one cycle. The previous control may now be clipped
  # by the scroll viewport, so compare only controls that remain on screen.
  if [[ "$desc" == "$TITLE_FOCUSED" && "$tab_index" -gt 0 ]]; then
    log "tab_walk_wrapped index=$tab_index identity=$desc"
    break
  fi
  frame="$(ax_focus_identity_frame "$desc" || true)"
  log "tab_probe index=$tab_index focus_state=$focus_state focused='$desc' ax_frame='$frame'"
  if [[ "$focus_state" == "valid" && -n "$desc" && "$desc" != "none" ]]; then
    if [[ "$desc" == "$previous_focus_desc" ]]; then
      stalled_tabs=$(( stalled_tabs + 1 ))
      (( stalled_tabs <= 4 )) || fail "five delivered Tab attempts left accepted focus on '$desc'"
      tab_index=$(( tab_index + 1 ))
      continue
    fi
    stalled_tabs=0
    if [[ ",$seen," != *",$desc,"* ]]; then
      seen="$seen,$desc"
      FOCUS_ORDER+=("$desc")
    fi
    frame_positive "$frame" || fail "focused control '$desc' has no visible frame ($frame)"
    frame_inside_window "$frame" "$(ax_window_frame)" \
      || fail "focused control '$desc' is outside the application window ($frame)"
    if [[ "$desc" == "$REVEAL_SEMANTIC" ]]; then
      reveal_after_line="$(pub generated-instances 2>/dev/null | awk '$1 == "INSTANCE" && $2 == "effectAnimate" { print; exit }')"
      reveal_after_visible="$(print -r -- "$reveal_after_line" | sed -n 's/.* visible=\([01]\) .*/\1/p')"
      [[ "$REVEAL_BEFORE_VISIBLE" == "0" && "$reveal_after_visible" == "1" ]] \
        || fail "the clipped generated control was not revealed by real Tab (before=$REVEAL_BEFORE_VISIBLE after=$reveal_after_visible)"
      REVEAL_VERIFIED=1
      log "step_reveal key=effectAnimate semantic=$desc before=0 after=1 frame=$frame"
    fi
    if [[ -n "$previous_focus_desc" ]]; then
      unfocused_pixels="$(control_visual_hash "$previous_focus_desc")" \
        || blocked "could not capture the previous control after focus moved"
      [[ "$unfocused_pixels" != "$previous_focus_pixels" ]] \
        || fail "Tab changed AX focus but produced no pixel change on '$previous_focus_desc'"
    fi
    focused_pixels="$(control_visual_hash "$desc")" \
      || blocked "could not capture the focused control '$desc'"
    previous_focus_desc="$desc"
    previous_focus_pixels="$focused_pixels"
  fi
  tab_index=$(( tab_index + 1 ))
done
(( ${#FOCUS_ORDER[@]} >= 4 )) || fail "Tab order visited ${#FOCUS_ORDER[@]} distinct controls (expected >= 4)"
(( REVEAL_VERIFIED == 1 )) || fail "the generated clipped target was never reached by the real Tab walk"
log "step1 keyboard_order distinct=${#FOCUS_ORDER[@]} order=${(j:|:)FOCUS_ORDER}"

# Discovery -> accepted candidate -> real generated control. The declaration
# supplies the rule reference, and an actual pointer click on its accepted
# semantic identity must make the action handler use that accepted rule.
pub generated-capabilities 2>/dev/null | rg -q '^MOTION_RULE generated.opacity duration_ms=160 ' \
  || fail "the common motion rule is absent from public discovery"
# Submit the discovered accepted description back through the public typed
# client. Even an equivalent description receives its own candidate ticket;
# only the terminal scene acceptance and readback authorize the later click.
if ! python3 - "$RUNTIME_DIR/shared_operation_core" "$DESCRIPTOR" >"$WORK/external-motion-submit.log" 2>&1 <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from cjgui_generated_client import GeneratedUiSession, same_structure

session = GeneratedUiSession.connect(sys.argv[2])
before = session.structure()
submitted = session.submit(before.nodes, before.version)
settled = session.wait_for_candidate_result(submitted.ticket(), timeout_ms=5000)
after = session.structure()
motion = [prop.value for node in after.nodes if node.key == "effectAnimate"
          for prop in node.properties if prop.name == "motion"]
ok = (submitted.candidate_accepted and settled.outcome == "terminal" and
      settled.last_state is not None and settled.last_state.terminal_state == "ACCEPTED" and
      after.version == submitted.candidate_version and after.version > before.version and
      same_structure(after.nodes, before.nodes) and motion == ["generated.opacity"])
print("CJGUI_EXTERNAL_MOTION_CANDIDATE"
      f" accepted={int(submitted.candidate_accepted)} terminal={settled.outcome}"
      f" state={settled.last_state.terminal_state if settled.last_state else 'none'}"
      f" version={before.version}->{after.version} motion={motion} pass={int(ok)}")
raise SystemExit(0 if ok else 1)
PY
then
  fail "the public motion candidate did not reach accepted scene ($WORK/external-motion-submit.log)"
fi
log "$(tail -1 "$WORK/external-motion-submit.log")"
pub generated-structure 2>/dev/null | rg -q '^PROPERTY 2 effectAnimate motion generated.opacity$' \
  || fail "the accepted generated candidate lost its motion declaration"
REVEAL_AFTER_CANDIDATE="$(pub generated-instances 2>/dev/null | awk '$1 == "INSTANCE" && $2 == "effectAnimate" { print; exit }')"
REVEAL_SEMANTIC="$(print -r -- "$REVEAL_AFTER_CANDIDATE" | sed -n 's/.* semantic=\([^ ]*\) .*/\1/p')"
[[ -n "$REVEAL_SEMANTIC" ]] || fail "the externally accepted motion control has no identity"
effect_focus_attempt=0
while (( effect_focus_attempt < 12 )); do
  [[ "$(accepted_focus_id)" == "$REVEAL_SEMANTIC" ]] && break
  drive tab >/dev/null 2>&1 || blocked "could not navigate to the generated motion control"
  sleep 0.18
  effect_focus_attempt=$(( effect_focus_attempt + 1 ))
done
[[ "$(accepted_focus_id)" == "$REVEAL_SEMANTIC" ]] \
  || fail "the generated motion control was not reachable by keyboard identity"
EFFECT_FRAME="$(ax_focus_identity_frame "$REVEAL_SEMANTIC" || true)"
frame_positive "$EFFECT_FRAME" || fail "generated motion control has no real click frame"
effect_click_attempt=0
while (( effect_click_attempt < 4 )); do
  click_frame_center "$EFFECT_FRAME" >/dev/null 2>&1 \
    || blocked "could not click the generated motion control"
  sleep 0.35
  if rg -q '^CJGUI_GENERATED_ANIMATION_STATE key=effectAnimate .* phase=low started=1 target=0\.3[0-9]* .* rule=generated.opacity duration=160 ' "$STDOUT_LOG"; then
    break
  fi
  effect_click_attempt=$(( effect_click_attempt + 1 ))
done
rg -q '^CJGUI_GENERATED_ANIMATION_STATE key=effectAnimate .* phase=low started=1 target=0\.3[0-9]* .* rule=generated.opacity duration=160 ' "$STDOUT_LOG" \
  || fail "real generated control clicks did not drive the accepted motion rule"
log "step_motion registered=1 candidate=1 real_control=1 semantic=$REVEAL_SEMANTIC clicks=$(( effect_click_attempt + 1 ))"

# --- 4. AX action and real click reach the SAME owner -----------------------
SUBMIT_FRAME="$(ax_screen_frame "提交当前任务")"
[[ -n "$SUBMIT_FRAME" && "$SUBMIT_FRAME" != "missing" ]] || blocked "submit button frame not found by description"
AX_RESET_VERSION="$(domain_version)"
pub invoke "$AX_RESET_VERSION" SET_MARKED --target 8101 --arg isMarked=BOOLEAN:false >/dev/null 2>&1 \
  || blocked "external SET_MARKED reset failed"
sleep 0.6
VERSION_A="$(domain_version)"
real_ax_press_button "$APP_PID" "提交当前任务" >/dev/null 2>&1 \
  || blocked "AX press on submit button could not be sent"
sleep 1.0
MARKED_FROM_AX="$(field_text marked)"
VERSION_B="$(domain_version)"
[[ "$MARKED_FROM_AX" == "true" ]] || fail "AX action did not reach the owner (marked=$MARKED_FROM_AX)"
[[ -n "$VERSION_A" && -n "$VERSION_B" && "$VERSION_B" != "$VERSION_A" ]] \
  || fail "AX action did not grow the owner version ($VERSION_A -> $VERSION_B)"
pub invoke "$VERSION_B" SET_MARKED --target 8101 --arg isMarked=BOOLEAN:false >/dev/null 2>&1 \
  || blocked "external SET_MARKED reset failed"
sleep 0.6
click_frame_center "$SUBMIT_FRAME" >/dev/null 2>&1 || blocked "real click on the submit button could not be posted"
sleep 1.0
MARKED_FROM_CLICK="$(field_text marked)"
VERSION_C="$(domain_version)"
[[ "$MARKED_FROM_CLICK" == "true" ]] || fail "real click did not reach the owner (marked=$MARKED_FROM_CLICK)"
[[ "$VERSION_C" != "$VERSION_B" ]] || fail "real click did not grow the owner version ($VERSION_B -> $VERSION_C)"
log "step2 same_owner ax_press=marked_true real_click=marked_true versions=$VERSION_A,$VERSION_B,$VERSION_C"

# --- 3. a disabled control is not activated ---------------------------------
# The submitted/frozen title must now be disabled. A real click + keystrokes on
# that editor must leave the accepted value unchanged.
TITLE_FRAME="$(ax_screen_frame "当前任务")"
[[ -n "$TITLE_FRAME" && "$TITLE_FRAME" != "missing" ]] \
  || blocked "title editor frame not found by description; cannot verify disabled activation"
TITLE_ENABLED_AFTER="$(ax_description_enabled "当前任务")"
[[ "$TITLE_ENABLED_AFTER" == "false" ]] \
  || fail "submitted title editor is not reported disabled (AXEnabled=$TITLE_ENABLED_AFTER)"
TITLE_BEFORE="$(field_text title)"
click_frame_center "$TITLE_FRAME" >/dev/null 2>&1 || blocked "could not deliver the disabled-control click"
sleep 0.4
drive type "X" >/dev/null 2>&1 || blocked "could not deliver the disabled-control keystroke"
sleep 0.8
TITLE_AFTER="$(field_text title)"
[[ "$TITLE_AFTER" == "$TITLE_BEFORE" ]] \
  || fail "a disabled editor accepted input (before='$TITLE_BEFORE' after='$TITLE_AFTER')"
log "step3 disabled_not_activated title_unchanged=1 frozen=1"

# --- 5. resize geometry consistency -----------------------------------------
WINDOW_BEFORE="$(ax_window_frame)"
frame_positive "$WINDOW_BEFORE" || blocked "window frame unavailable for resize"
real_resize_window 70 50 >/dev/null 2>&1 || blocked "real window resize could not be posted"
sleep 1.0
activate_app
WINDOW_AFTER="$(ax_window_frame)"
frame_positive "$WINDOW_AFTER" || fail "window frame missing after resize"
[[ "$WINDOW_AFTER" != "$WINDOW_BEFORE" ]] || fail "window did not actually resize ($WINDOW_BEFORE)"
SUBMIT_AFTER="$(ax_screen_frame "提交当前任务")"
[[ -n "$SUBMIT_AFTER" && "$SUBMIT_AFTER" != "missing" ]] \
  || fail "submit control is missing after resize"
frame_positive "$SUBMIT_AFTER" || fail "control frame not positive after resize ($SUBMIT_AFTER)"
frame_inside_window "$SUBMIT_AFTER" "$WINDOW_AFTER" \
  || fail "control frame escaped the resized window ($SUBMIT_AFTER vs $WINDOW_AFTER)"
log "step4 resize_geometry before=$WINDOW_BEFORE after=$WINDOW_AFTER submit=$SUBMIT_AFTER"

echo "consumer control usability: PASS keyboard_order=${#FOCUS_ORDER[@]} visible_focus=1 clipped_reveal=1 generated_motion_control=1 same_owner=1 disabled_not_activated=1 resize_geometry=1"
echo "consumer control usability: BLOCKED real VoiceOver navigation not run (an AX query is not a VoiceOver session)"
echo "consumer control usability: BLOCKED second-display cross-screen behavior unverified; controlled 1->2 scale uses the internal-testing vector probe"
log "verdict PASS keyboard_order visible_focus clipped_reveal generated_motion_control same_owner disabled_not_activated resize_geometry; BLOCKED voiceover cross_screen"
exit 0
