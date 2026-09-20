#!/usr/bin/env zsh
# Shared real-desktop-input helpers for CJGUI verification scripts.
#
# Extracted verbatim from verify_framework_preview_consumer_chains.sh, where the
# driver, the AX frame walk and the bounded type/readback loop were first
# measured. A caller must define before sourcing:
#   RUNTIME_DIR  repository runtime/cjgui root (driver source path)
#   WORK         per-round work directory (driver binary + logs)
#   CLIENT       public operation client (python)
#   log / fail   logging helpers
# and set AX_PID to the round process before an edit. The exported/author
# distinction is entirely in those variables: no author-runtime seam is added.
#
# Requires cjgui_ax from lib_cjgui_instance.sh. The caller keeps its own shell
# options: this file does not change `set -u`/`set -e`.
DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
DRIVER=""
INPUT_BLOCKED=""
REAL_EDIT_MODE=""
REAL_EDIT_BEFORE=""
REAL_EDIT_AFTER=""
REAL_EDIT_FRAME=""
RE_DESCRIPTOR=""
RE_FIELD_ID=""
RE_TARGET=""

session_locked() {
  local state
  state="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 \
    | awk -F= '{print $2}' | tr -d '[:space:]' || true)"
  [[ "$state" == "Yes" ]]
}
prepare_desktop_driver() {
  if session_locked; then
    INPUT_BLOCKED="session_locked (CGSSessionScreenIsLocked=Yes)"
    log "BLOCKED desktop_input reason=session_locked"
    return 1
  fi
  if ! command -v swiftc >/dev/null 2>&1; then
    INPUT_BLOCKED="swiftc_unavailable"
    log "BLOCKED desktop_input reason=swiftc_unavailable"
    return 1
  fi
  DRIVER="$WORK/cjgui_desktop_input_driver"
  if ! swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1; then
    INPUT_BLOCKED="driver_build_failed"
    log "BLOCKED desktop_input reason=driver_build_failed log=$WORK/driver-build.log"
    return 1
  fi
  log "step0 desktop_input_driver=built tool=$DRIVER source=$DRIVER_SOURCE role=verification_tool"
  return 0
}

AX_PID=""
drive() { "$DRIVER" "$@" >> "$WORK/driver.log" 2>&1; }
hex_to_text() {
  python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'
}
activate_app() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
  end tell" >/dev/null 2>&1 || true
}
app_frontmost() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    return frontmost of p
  end tell" 2>/dev/null | tail -1 || true
}
ax_focused_description() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    try
      set e to value of attribute \"AXFocusedUIElement\" of p
      return (description of e)
    on error
      return \"missing\"
    end try
  end tell" 2>/dev/null | tail -1 || true
}
ax_window_frame() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string)
  end tell" 2>/dev/null | tail -1 || true
}
# The window must be key before posted input is routed into it; the point sits
# in the title band so becoming key cannot press a self-drawn control.
make_window_key() {
  local frame x y w
  frame="$(ax_window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> ]] || return 1
  drive click $(( x + w - 20 )) $(( y + 40 ))
  sleep 0.6
  return 0
}
# Bounded AX read of one element frame by collection kind and description.
# The typed collection (`text field`, `checkbox`) is used instead of
# `entire contents`: on this host an exported cjgui window does not expose its
# descendants through `entire contents`, while `every text field of window 1`
# lists the generated editors together with their accessibility descriptions
# (measured for the exported rule consumer: "规则名称编辑" / "启用状态编辑").
ax_kind_frame() { # ax_kind_frame <collection-kind> <description> -> "x y w h" | missing
  local kind="$1" wanted="$2"
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $AX_PID
    try
      set ds to description of every $kind of window 1 of p
      set ps to position of every $kind of window 1 of p
      set ss to size of every $kind of window 1 of p
      repeat with i from 1 to (count of ds)
        try
          if (item i of ds) is \"$wanted\" then
            set pp to item i of ps
            set ssz to item i of ss
            return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ssz) as string) & \" \" & ((item 2 of ssz) as string)
          end if
        end try
      end repeat
    end try
    return \"missing\"
  end tell" 2>/dev/null | tail -1 || true
}
click_frame_center() { # click_frame_center "x y w h"
  local frame="$1" x y w h
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  h="$(print -r -- "$frame" | awk '{print $4}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> && "$h" == <-> ]] || return 1
  (( w > 0 && h > 0 )) || return 1
  drive click $(( x + w / 2 )) $(( y + h / 2 ))
  return 0
}
click_ax_element() { # click_ax_element <collection-kind> <description> -> prints "x y w h"
  local kind="$1" description="$2" frame
  frame="$(ax_kind_frame "$kind" "$description")"
  [[ "$frame" != "missing" && -n "$frame" ]] || return 1
  click_frame_center "$frame" || return 1
  sleep 0.8
  print -r -- "$frame"
  return 0
}
# Real modifier press + letter with that flag + release: the chord the tree
# keyboard verifier uses for Command-A, so NSTextView's own select-all runs and
# a following typed string replaces the field content instead of appending.
chord_select_all() {
  drive key-down 55
  drive shortcut command 0
  drive key-up 55
  sleep 0.4
}
window_focus_for() { python3 "$CLIENT" "$1" window-interaction 2>/dev/null | awk '/^WINDOW_FOCUS /{print $2}'; }
field_hex_value() { # field_hex_value <descriptor> <fieldId> <token>
  python3 "$CLIENT" "$1" generated-fields 2>/dev/null | awk -v id="$2" -v tag="$3" '
    $1 == "FIELD" && $2 == id { for (i = 1; i <= NF; i++) if ($i == tag) { print $(i + 1); exit } }'
}
field_text_value() { field_hex_value "$1" "$2" DRAFT_HEX | hex_to_text; }
# A read issued while the exported window commits a refresh can come back empty
# even though the owner value is set; the exact-value check below retries within
# a fixed bound instead of treating an empty read as a delivered edit.
field_text_value_retry() { # field_text_value_retry <descriptor> <fieldId> [tries]
  local descriptor="$1" fieldId="$2" tries="${3:-8}" attempt=0 value=""
  while (( attempt < tries )); do
    value="$(field_text_value "$descriptor" "$fieldId")"
    if [[ -n "$value" ]]; then
      print -r -- "$value"
      return 0
    fi
    sleep 0.3
    attempt=$(( attempt + 1 ))
  done
  print -r -- ""
  return 0
}

# real_generated_text_edit <label> <descriptor> <fieldId> <description> <kind> <target>
# Focus path: a real press into the generated editor's own AX frame (which also
# makes the exported window key), then a Tab walk as the fallback. The edit is
# accepted only when the owner read-back equals the target exactly (replace) or
# the exact pre-edit value plus the target (append, caret at the end).
# Whether a consumer answers the public window-focus query. The rule consumer
# exposes it (component-* focus scopes); the second consumer does not authorize
# it, so its focus is judged by the owner read-back alone instead of by Tab
# traversal.
focus_query_supported() { # focus_query_supported <descriptor>
  python3 "$CLIENT" "$1" window-interaction 2>/dev/null | grep -q '^WINDOW_FOCUS '
}

# real_type_target: types RE_TARGET into the currently focused generated editor
# and accepts only an EXACT owner read-back equal to the target (replace). Uses
# REAL_EDIT_BEFORE / RE_* globals.
#
# The Command-A chord that clears the caret's field can miss if the editor is not
# yet first responder, which makes the typed text append instead of replace. That
# is retried (bounded) rather than accepted: every caller asserts the exact target
# value afterwards, so reporting `append` as a delivered edit only re-surfaced
# later as an unrelated read-back mismatch. A persistent append is reported as a
# delivery failure so the caller can record control input as blocked/fall back.
real_type_target() {
  local attempt=0
  while (( attempt < 3 )); do
    chord_select_all
    drive type "$RE_TARGET"
    sleep 1.5
    REAL_EDIT_AFTER="$(field_text_value_retry "$RE_DESCRIPTOR" "$RE_FIELD_ID")"
    if [[ -z "$REAL_EDIT_AFTER" ]]; then
      log "diag real_type_target empty_read attempt=$attempt before='$REAL_EDIT_BEFORE' target='$RE_TARGET'"
      return 1
    fi
    if [[ "$REAL_EDIT_AFTER" == "$RE_TARGET" && "$REAL_EDIT_BEFORE" != "$RE_TARGET" ]]; then
      REAL_EDIT_MODE="replace"; return 0
    fi
    if [[ "$REAL_EDIT_AFTER" == "${REAL_EDIT_BEFORE}${RE_TARGET}" ]]; then
      # The select-all chord did not take: the text was appended. Retry the chord
      # and retype (a working chord replaces the accumulated text exactly); if it
      # keeps failing the mismatch branch below reports the real value.
      log "diag real_type_target append_retry attempt=$attempt after='$REAL_EDIT_AFTER' target='$RE_TARGET'"
      attempt=$(( attempt + 1 ))
      sleep 0.5
      continue
    fi
    log "diag real_type_target mismatch attempt=$attempt before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RE_TARGET'"
    return 1
  done
  log "diag real_type_target append_only before='$REAL_EDIT_BEFORE' after='${REAL_EDIT_AFTER:-}' target='$RE_TARGET'"
  return 1
}

# real_ax_press_button <pid> <label>
# Real press on the button whose accessibility description/title/name is exactly
# `label`. The three attributes are tried in order because a self-drawn window may
# publish the caption through any of them; the caller decides whether a failure is
# a product failure or an environment limitation.
real_ax_press_button() {
  local pid="$1" label="$2" attribute
  for attribute in description title name; do
    if cjgui_ax 15 -e "tell application \"System Events\"
      set p to first process whose unix id is $pid
      set frontmost of p to true
      perform action \"AXRaise\" of window 1 of p
      set b to first button of window 1 of p whose $attribute is \"$label\"
      click b
      return \"ok\"
    end tell" >/dev/null 2>&1; then
      sleep 0.8
      return 0
    fi
  done
  return 1
}

# real_focus_text_edit <label> <descriptor> <fieldId> <focusMatch> <target>
# Real desktop input into the editor that the window itself reports as owning the
# keyboard focus. `focusMatch` is the reported focus value to wait for: the
# prefix `component-` for a generated control (its numeric identity is not
# caller-known), or the exact `field-<fieldId>` of a handwritten bound field, so
# a walk can never type into a different handwritten field by accident. The
# window is made key first, real Tab presses walk the focus, and the owner
# read-back decides acceptance: only an exact replacement counts.
real_focus_text_edit() {
  local label="$1" descriptor="$2" fieldId="$3" focusMatch="$4" target="$5"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  RE_DESCRIPTOR="$descriptor"; RE_FIELD_ID="$fieldId"; RE_TARGET="$target"
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  local i=0 focus="" attempt=0 keyed=""
  while (( attempt < 3 )); do
    activate_app
    make_window_key || true
    keyed="$(app_frontmost)"
    log "diag real_text_edit_key label=$label attempt=$attempt frontmost=$keyed"
    [[ "$keyed" == "true" ]] && break
    sleep 0.8
    attempt=$(( attempt + 1 ))
  done
  while (( i < 100 )); do
    focus="$(window_focus_for "$descriptor")"
    if [[ "$focus" == ${focusMatch}* ]]; then
      if real_type_target; then REAL_EDIT_MODE="tab_${REAL_EDIT_MODE} focus=$focus"; return 0; fi
    fi
    drive tab
    sleep 0.3
    if (( i % 20 == 19 )); then log "diag real_text_edit_tab label=$label i=$i focus=$focus"; fi
    i=$(( i + 1 ))
  done
  log "diag real_text_edit no_edit label=$label focus_match='$focusMatch' tabs=$i last_focus=$focus frontmost=$(app_frontmost)"
  return 1
}

# real_generated_text_edit <label> <descriptor> <fieldId> <description> <kind> <target>
# Real desktop input into one generated editor:
#   1. Tab traversal to the generated component while the consumer publishes the
#      window focus (the pattern verify_generated_ui_human_input.sh uses);
#   2. otherwise a real press into the editor's own AX frame (twice: the first
#      press can only activate an inactive exported window);
# A step succeeds only when the owner read-back is exactly the target.
real_generated_text_edit() {
  local label="$1" descriptor="$2" fieldId="$3" description="$4" kind="$5" target="$6"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  RE_DESCRIPTOR="$descriptor"; RE_FIELD_ID="$fieldId"; RE_TARGET="$target"
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  if focus_query_supported "$descriptor"; then
    # Rule-style consumer: walk the window focus with real Tab presses and type
    # only while a generated component owns the focus, so a handwritten field is
    # never written by accident (measured: the generated editor is the
    # component-* focus at tab 33 on the exported rule consumer).
    if real_focus_text_edit "$label" "$descriptor" "$fieldId" "component-" "$target"; then
      return 0
    fi
    log "diag real_text_edit no_edit label=$label description='$description' frontmost=$(app_frontmost)"
    return 1
  fi
  # Consumer without the public focus query (the second consumer): press the
  # generated editor's own AX frame, which both keys the window and focuses the
  # editor; the owner read-back decides acceptance. The exported rule window
  # (and the UI-only tree window) can overlap this frame, so the window is keyed
  # first and the press+type pair is bounded to two attempts.
  make_window_key || true
  local attempt2=0
  while (( attempt2 < 2 )); do
    REAL_EDIT_FRAME="$(click_ax_element "$kind" "$description")" || REAL_EDIT_FRAME=""
    if [[ -n "$REAL_EDIT_FRAME" ]]; then
      click_frame_center "$REAL_EDIT_FRAME" || true
      sleep 0.8
      log "diag real_text_edit_focus label=$label attempt=$attempt2 focused_description='$(ax_focused_description)'"
      if real_type_target; then REAL_EDIT_MODE="frame_${REAL_EDIT_MODE}"; return 0; fi
    fi
    attempt2=$(( attempt2 + 1 ))
  done
  log "diag real_text_edit no_edit label=$label description='$description' frame='$REAL_EDIT_FRAME' frontmost=$(app_frontmost)"
  log "diag real_text_edit fields='$(python3 "$CLIENT" "$descriptor" generated-fields 2>/dev/null | grep '^FIELD ' | tr '\n' ';')'"
  return 1
}

# real_generated_boolean_toggle <label> <descriptor> <fieldId> <description> [kind]
# A real press on the generated boolean control; a single bounded second press
# covers a first press that only activated the window. Returns 0 only when the
# owner boolean actually flipped.
real_generated_boolean_toggle() {
  local label="$1" descriptor="$2" fieldId="$3" description="$4" kind="${5:-checkbox}"
  REAL_EDIT_MODE=""; REAL_EDIT_FRAME=""
  REAL_EDIT_BEFORE="$(field_text_value "$descriptor" "$fieldId")"
  activate_app
  log "diag real_boolean_toggle_key label=$label frontmost=$(app_frontmost)"
  REAL_EDIT_FRAME="$(click_ax_element "$kind" "$description")" || return 1
  sleep 1.0
  REAL_EDIT_AFTER="$(field_text_value "$descriptor" "$fieldId")"
  if [[ "$REAL_EDIT_AFTER" != "$REAL_EDIT_BEFORE" && -n "$REAL_EDIT_AFTER" ]]; then
    REAL_EDIT_MODE="click_toggle frame=$REAL_EDIT_FRAME"; return 0
  fi
  log "diag real_boolean_toggle label=$label frame='$REAL_EDIT_FRAME' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' frontmost=$(app_frontmost)"
  REAL_EDIT_FRAME="$(click_ax_element "$kind" "$description")" || return 1
  sleep 1.0
  REAL_EDIT_AFTER="$(field_text_value "$descriptor" "$fieldId")"
  if [[ "$REAL_EDIT_AFTER" != "$REAL_EDIT_BEFORE" && -n "$REAL_EDIT_AFTER" ]]; then
    REAL_EDIT_MODE="click_toggle_second frame=$REAL_EDIT_FRAME"; return 0
  fi
  return 1
}

assert_boolean_flip() { # assert_boolean_flip <what>
  [[ "$REAL_EDIT_BEFORE" == "true" || "$REAL_EDIT_BEFORE" == "false" ]] || \
    fail "$1 boolean before is not a boolean ('$REAL_EDIT_BEFORE')"
  [[ "$REAL_EDIT_AFTER" == "true" || "$REAL_EDIT_AFTER" == "false" ]] || \
    fail "$1 boolean after is not a boolean ('$REAL_EDIT_AFTER')"
  [[ "$REAL_EDIT_BEFORE" != "$REAL_EDIT_AFTER" ]] || \
    fail "$1 boolean press did not flip the owner value (still $REAL_EDIT_BEFORE)"
}
