#!/usr/bin/env zsh
# Runtime-generated-UI closed loop on the SECOND consumer (collaboration task
# board: a different existing domain, different fields/actions and different
# catalog bounds). Proves the same public entry points work outside the rule
# business without copying an interpreter or a rule-private branch.
#
# step4b/4b2 additionally prove that a generated image reference resolves from
# the second domain's OWN declaration (logical key + exact version, never a
# path), and step4c proves a declared constraint/font reaches the real accepted
# geometry and survives a REAL window resize together with the draft and focus
# on the same binding.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/generated_panel_consumer"
OUTPUT_DIR="${CJGUI_GENERATED_UI_SECOND_TMPDIR:-/private/tmp/cjgui-generated-ui-second}"
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

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
# The SHARED real-input driver. It resolves the exact accepted semanticId and
# refuses to type until the window reports that identity, so a press on this
# window can never write another field.
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

# This consumer owns exactly ONE window, so its host advertises no window
# targets and RE_WINDOW_TARGET stays unset on purpose: the target-qualified
# `window-interaction <target>` read belongs to the explicit multi-window host
# (verify_multi_window_application.sh enumerates targets there). Exactness here
# comes from the driver's accepted-identity focus read, and this chain REFUSES
# the AX owner-readback fallback: an edit only counts when the window's own
# focus projection reported the exact accepted semanticId. Without this, a
# label/role match could pass as "the exact instance received the input".
export REQUIRE_EXACT_INSTANCE_EVIDENCE=1

# --- real desktop input for the generated editors ---------------------------
DRIVER_SOURCE="$RUNTIME_DIR/native/tests/desktop_input_driver.swift"
DRIVER=""
DESKTOP_BLOCKED=""
prepare_driver() {
  if ! command -v swiftc >/dev/null 2>&1; then
    DESKTOP_BLOCKED="swiftc unavailable for the desktop input driver"
    return 1
  fi
  DRIVER="$WORK/cjgui_desktop_input_driver"
  swiftc -O "$DRIVER_SOURCE" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1 || {
    DESKTOP_BLOCKED="desktop input driver did not build"
    return 1
  }
  return 0
}
# Bounded AX read of one editor frame by its accessibility description.
# The lookup is role-agnostic on purpose: the generated boolean editor is
# exposed with the checkbox role, so `first text field ... whose description`
# never matched it and the whole desktop step was reported BLOCKED even though
# the element was present. The element is located wherever it sits in the
# window's accessibility tree, and the role it was found under is recorded so
# the evidence shows what the projection actually produced.
ax_editor_frame() { # ax_editor_frame <description> [role] -> "x y w h role" or "missing"
  # A generated control can share its accessibility description with an
  # enclosing row/container. Search the window's direct elements first and the
  # whole tree after, and prefer the SMALLEST matching element inside each pass:
  # a container's centre is not a hit point on the control itself.
  local role="${2:-}"
  cjgui_ax 20 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set wanted to \"$1\"
    set wantedRole to \"$role\"
    set bestFrame to \"missing\"
    set bestArea to -1
    -- The typed collection lists the generated editors on this host, while
    -- The full contents may not expose descendants at all.
    set collectionKind to \"\"
    if wantedRole is \"AXTextField\" then set collectionKind to \"text field\"
    if wantedRole is \"AXCheckBox\" then set collectionKind to \"checkbox\"
    try
      if collectionKind is \"text field\" then
        repeat with e in (every text field of window 1 of p)
          try
            if wantedRole is \"\" or (role of e) is wantedRole then
              if (description of e) is wanted then
                set pp to position of e
                set ss to size of e
                set area to ((item 1 of ss) as integer) * ((item 2 of ss) as integer)
                if bestArea < 0 or area < bestArea then
                  set bestArea to area
                  set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string) & \" \" & (role of e)
                end if
              end if
            end if
          end try
        end repeat
      else if collectionKind is \"checkbox\" then
        repeat with e in (every checkbox of window 1 of p)
          try
            if wantedRole is \"\" or (role of e) is wantedRole then
              if (description of e) is wanted then
                set pp to position of e
                set ss to size of e
                set area to ((item 1 of ss) as integer) * ((item 2 of ss) as integer)
                if bestArea < 0 or area < bestArea then
                  set bestArea to area
                  set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string) & \" \" & (role of e)
                end if
              end if
            end if
          end try
        end repeat
      end if
    end try
    if bestFrame is not \"missing\" then return bestFrame
    try
      repeat with e in (every UI element of window 1 of p)
        try
          if (description of e) is wanted then
            set matchedRole to role of e
            if wantedRole is \"\" or matchedRole is wantedRole then
              set pp to position of e
              set ss to size of e
              set area to ((item 1 of ss) as integer) * ((item 2 of ss) as integer)
              if bestArea < 0 or area < bestArea then
                set bestArea to area
                set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string) & \" \" & matchedRole
              end if
            end if
          end if
        end try
      end repeat
    end try
    if bestFrame is \"missing\" then
      try
        repeat with e in (entire contents of window 1 of p)
          try
            if (description of e) is wanted then
              set matchedRole to role of e
              if wantedRole is \"\" or matchedRole is wantedRole then
                set pp to position of e
                set ss to size of e
                set area to ((item 1 of ss) as integer) * ((item 2 of ss) as integer)
                if bestArea < 0 or area < bestArea then
                  set bestArea to area
                  set bestFrame to ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string) & \" \" & ((item 2 of ss) as string) & \" \" & matchedRole
                end if
              end if
            end if
          end try
        end repeat
      end try
    end if
    return bestFrame
  end tell" 2>/dev/null | tail -1 || true
}
ax_focused_description() {
  cjgui_ax 10 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    try
      return description of (first UI element of window 1 of p whose focused is true)
    end try
    return \"none\"
  end tell" 2>/dev/null | tail -1 || true
}
window_frame() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set pp to position of window 1 of p
    set ss to size of window 1 of p
    return ((item 1 of pp) as string) & \" \" & ((item 2 of pp) as string) & \" \" & ((item 1 of ss) as string)
  end tell" 2>/dev/null | tail -1 || true
}
activate_and_key() {
  cjgui_ax 15 -e "tell application \"System Events\"
    set p to first process whose unix id is $APP_PID
    set frontmost of p to true
    perform action \"AXRaise\" of window 1 of p
  end tell" > /dev/null 2>&1 || true
  local frame x y w
  frame="$(window_frame)"
  x="$(print -r -- "$frame" | awk '{print $1}')"
  y="$(print -r -- "$frame" | awk '{print $2}')"
  w="$(print -r -- "$frame" | awk '{print $3}')"
  [[ "$x" == <-> && "$y" == <-> && "$w" == <-> ]] || return 1
  "$DRIVER" click $(( x + w - 20 )) $(( y + 40 )) >/dev/null 2>&1
  sleep 0.6
  return 0
}

# --- per-round instance (own bundle id, exec name, directory, descriptor) ---
NAME_TOKEN="CJGUICollaborationStarter"
BUNDLE_TOKEN="org.example.cjgui.collaboration-starter"
ROUND_DIR="$WORK/round-app"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME_TOKEN" "Second${RUN_TAG}" "$BUNDLE_TOKEN" \
  || fail "per-round application copy failed"
ROUND_EXEC="$ROUND_DIR/target/release/${NAME_TOKEN}Second${RUN_TAG}.app/Contents/MacOS/${NAME_TOKEN}Second${RUN_TAG}"
APP_PID=""
DESCRIPTOR=""
cleanup() {
  cjgui_terminate_owned "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" || true
  log "cleanup: instance closed=$(cjgui_pid_owns "$APP_PID" "${DESCRIPTOR:-}" "$ROUND_EXEC" "$ROUND_DIR" && echo no || echo yes)"
}
trap cleanup EXIT

ROUND_STARTED="$(date +%s)"
STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
DESCRIPTOR=""
waited=0
while (( waited < 150 )); do
  DESCRIPTOR="$(grep 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' "$STDOUT_LOG" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
  if [[ -n "$DESCRIPTOR" && -f "$DESCRIPTOR" ]]; then break; fi
  sleep 2; waited=$((waited + 2))
done
[[ -f "${DESCRIPTOR:-}" ]] || fail "second consumer did not publish a descriptor"
APP_PID="$(cjgui_descriptor_owner_pid "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" "$ROUND_STARTED" || true)"
[[ -n "$APP_PID" ]] || fail "second consumer descriptor has no matching owner"
cjgui_pid_owns "$APP_PID" "$DESCRIPTOR" "$ROUND_EXEC" "$ROUND_DIR" || fail "second consumer pid is not this round's instance"
log "launched pid=$APP_PID descriptor=$DESCRIPTOR owner_verified=descriptor+exec+dir"

pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
structure_version() { pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
field_line() { pub generated-fields 2>/dev/null | awk -v id="$1" '$1 == "FIELD" && $2 == id {print}'; }
field_hex() { # field_hex <fieldId> <HEX-TAG>
  field_line "$1" | awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}'
}
hex_to_text() { python3 -c 'import sys; raw=sys.stdin.read().strip(); print("" if raw in ("", "-") else bytes.fromhex(raw).decode("utf-8","replace"))'; }
structure_version() { pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
scene_state() { pub generated-structure 2>/dev/null | awk '/^SCENE_STATE /{print $2}'; }
# Candidate receipt and scene acceptance are separate: wait for the accepted
# version instead of assuming the window already refreshed.
wait_for_structure_version() { # wait_for_structure_version <expected> [seconds]
  local expected="$1" limit="${2:-20}" waited=0
  while (( waited < limit )); do
    [[ "$(structure_version)" == "$expected" ]] && return 0
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  return 1
}

# --- 1. capability query (own bounds + own domain actions) -----------------
CAPS="$WORK/capabilities.txt"
pub generated-capabilities > "$CAPS" 2>&1 || true
grep -q '^KIND GENERATED_UI_CAPABILITIES' "$CAPS" || fail "capabilities query failed"
grep -q '^BOUNDS 8 64 6 160' "$CAPS" || fail "second consumer bounds missing"
grep -q '^ACTION TOGGLE_MARKED' "$CAPS" || fail "TOGGLE_MARKED action missing"
grep -q '^FIELD title' "$CAPS" || fail "title field missing from the definition-derived catalog"
grep -q '^FIELD marked' "$CAPS" || fail "marked field missing from the definition-derived catalog"
log "step1 capabilities_ok bytes=$(wc -c < "$CAPS" | tr -d ' ')"

# --- 2. S1 through the same entry ------------------------------------------
[[ "$(structure_version)" == "0" ]] || fail "initial structure version is not 0"
cat > "$WORK/s1.txt" <<'S1'
GENERATED_UI_STRUCTURE 1
NODE 0 board vertical
NODE 1 heading label
PROPERTY 1 heading text 任务生成面板
NODE 1 titleField textInput field=title
NODE 1 toggleBtn action action=TOGGLE_MARKED
PROPERTY 1 toggleBtn label 切换提交状态
END
S1
pub generated-submit --structure-version 0 --payload-file "$WORK/s1.txt" > "$WORK/submit-s1.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s1.log" || fail "S1 candidate was not received"
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/submit-s1.log" || fail "S1 candidate acceptance not reported"
grep -q '^VERSION_AFTER 0' "$WORK/submit-s1.log" || fail "candidate receipt advanced the accepted structure version"
wait_for_structure_version 1 || fail "S1 was never scene-accepted"
log "step2 s1_scene_accepted version=1 scene=$(scene_state)"

# --- 3. business action changes the record, public field read follows -------
# The structure version and the business owner version are separate
# counters: a business invoke uses the owner's own version.
DOMAIN_VERSION="$(pub get 2>/dev/null | awk '/^VERSION /{print $2}')"
pub invoke "$DOMAIN_VERSION" SET_TITLE --target 8101 --arg title=STRING:"生成第二消费者" > "$WORK/set-title.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/set-title.log" || fail "SET_TITLE failed"
TITLE_HEX="$(field_hex title DRAFT_HEX)"
[[ "$(print -r -- "$TITLE_HEX" | hex_to_text)" == "生成第二消费者" ]] || fail "field read did not show the new title"
log "step3 business_action_ok title=$(print -r -- "$TITLE_HEX" | hex_to_text)"

# --- 4. S2 re-order keeps the same field content ---------------------------
cat > "$WORK/s2.txt" <<'S2'
GENERATED_UI_STRUCTURE 1
NODE 0 board2 horizontal
NODE 1 toggleBtn2 action action=TOGGLE_MARKED
PROPERTY 1 toggleBtn2 label 重排后的按钮
NODE 1 titleAgain textInput field=title
END
S2
pub generated-submit --structure-version 1 --payload-file "$WORK/s2.txt" > "$WORK/submit-s2.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s2.log" || fail "S2 re-order candidate was not received"
wait_for_structure_version 2 || fail "S2 was never scene-accepted"
[[ "$(scene_state)" == "scene_accepted" ]] || fail "S2 scene state is $(scene_state)"
TITLE_AFTER_HEX="$(field_hex title DRAFT_HEX)"
[[ "$TITLE_AFTER_HEX" == "$TITLE_HEX" ]] || fail "field content did not survive the re-order"
grep -q 'NODE 1 titleAgain textInput field=title' <(pub generated-structure 2>/dev/null) || \
  fail "S2 field binding missing from the accepted structure"
log "step4 s2_reorder_ok field_survived=true"

# --- 4b. generated text/boolean editors write through the owner -------------
# The generated editor for each field uses the write operation declared in the
# single field definition (SET_TITLE / SET_MARKED) and the shared resource id,
# so a real desktop edit reaches the domain's own human owner entry.
cat > "$WORK/s3.txt" <<'S3'
GENERATED_UI_STRUCTURE 1
NODE 0 board3 vertical
NODE 1 cardIcon image
PROPERTY 1 cardIcon resource collaboration-beacon
PROPERTY 1 cardIcon resourceVersion 1
PROPERTY 1 cardIcon contentMode fill
PROPERTY 1 cardIcon fixedWidth 56
PROPERTY 1 cardIcon fixedHeight 56
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
NODE 1 markedEditor booleanInput field=marked
PROPERTY 1 markedEditor label 提交状态编辑
END
S3
BEFORE_TITLE="$(field_hex title DRAFT_HEX)"
BEFORE_MARKED="$(field_hex marked DRAFT_HEX)"
S3_VERSION="$(structure_version)"
pub generated-submit --structure-version "$S3_VERSION" --payload-file "$WORK/s3.txt" > "$WORK/submit-s3.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s3.log" || fail "generated editors structure was rejected"
wait_for_structure_version $((S3_VERSION + 1)) || fail "generated editors structure was never scene-accepted"
S3_STRUCTURE="$(pub generated-structure 2>/dev/null)"
grep -q 'NODE 1 titleEditor textInput field=title' <<< "$S3_STRUCTURE" || fail "generated text editor binding missing"
grep -q 'NODE 1 markedEditor booleanInput field=marked' <<< "$S3_STRUCTURE" || fail "generated boolean editor binding missing"
[[ "$(field_hex title DRAFT_HEX)" == "$BEFORE_TITLE" ]] || fail "field read changed without an edit"
log "step4b generated_editors_accepted version=$((S3_VERSION + 1))"

# The SAME accepted window carries a generated reference to the application's
# logical image resource: read-back names the resource and version, never a path.
pub generated-instances > "$WORK/s3-instances.txt" 2>&1 || true
grep -q '^INSTANCE cardIcon ' "$WORK/s3-instances.txt" \
  || fail "the accepted panel image instance is missing"
grep -q 'kind=image' "$WORK/s3-instances.txt" || fail "the accepted panel instance is not an image"
grep -q 'resource=collaboration-beacon' "$WORK/s3-instances.txt" \
  || fail "the panel instance does not name the logical resource"
grep -q 'resource_version=1' "$WORK/s3-instances.txt" \
  || fail "the panel instance does not name the accepted resource version"
grep -q 'composable-beacon.png' "$WORK/s3-instances.txt" \
  && fail "the panel instance projection leaked the application raster path"
log "step4b2 panel_image_resource_ok key=collaboration-beacon version=1 readback=resource_only"

if prepare_driver; then
  if activate_and_key; then
    # Real typing into the generated text editor.
    TFRAME="$(ax_editor_frame "任务标题编辑" "AXTextField")"
    if [[ -z "$DESKTOP_BLOCKED" && "$TFRAME" != "missing" && -n "$TFRAME" ]]; then
      tx="$(print -r -- "$TFRAME" | awk '{print $1}')"
      ty="$(print -r -- "$TFRAME" | awk '{print $2}')"
      tw="$(print -r -- "$TFRAME" | awk '{print $3}')"
      th="$(print -r -- "$TFRAME" | awk '{print $4}')"
      TROLE="$(print -r -- "$TFRAME" | awk '{print $5}')"
      # The first press may only key the window; each attempt re-clicks the
      # control's own frame, records the focused accessibility element, and
      # types. The owner read-back decides acceptance, not the click.
      local text_attempt=0
      local text_target="Zk9"
      AFTER_TITLE="$BEFORE_TITLE"
      while (( text_attempt < 3 )); do
        # A generated text editor's accessibility frame can span its whole row;
        # the editable area sits on the trailing side. The window is re-keyed and
        # the frame re-read on EVERY attempt: on this host a synthetic press can
        # be delivered while the window is not yet key (measured: two identical
        # presses in a row reached the owner, a third run's two presses did not),
        # so the attempt is bounded and the owner read-back still decides.
        activate_and_key || true
        TFRAME="$(ax_editor_frame "任务标题编辑" "AXTextField")"
        [[ "$TFRAME" != "missing" && -n "$TFRAME" ]] || break
        tx="$(print -r -- "$TFRAME" | awk '{print $1}')"
        ty="$(print -r -- "$TFRAME" | awk '{print $2}')"
        tw="$(print -r -- "$TFRAME" | awk '{print $3}')"
        th="$(print -r -- "$TFRAME" | awk '{print $4}')"
        TROLE="$(print -r -- "$TFRAME" | awk '{print $5}')"
        if (( text_attempt == 1 )); then
          "$DRIVER" click $(( tx + tw - 30 )) $(( ty + th / 2 )) >/dev/null 2>&1
        else
          "$DRIVER" click $(( tx + tw / 2 )) $(( ty + th / 2 )) >/dev/null 2>&1
        fi
        sleep 0.8
        log "diag real_text_edit_focus label=second_consumer attempt=$text_attempt frame='$tx $ty $tw $th role=$TROLE' focused_description='$(ax_focused_description)' window='$(window_frame)' frontmost='$(cjgui_ax 10 -e "tell application \"System Events\" to return name of first process whose frontmost is true" 2>/dev/null | tail -1)'"
        # The same real chord the tree keyboard verifier uses: a real Command
        # key-down, Command+A, key-up, then the typed string.
        "$DRIVER" key-down 55 >/dev/null 2>&1
        "$DRIVER" shortcut command 0 >/dev/null 2>&1
        "$DRIVER" key-up 55 >/dev/null 2>&1
        sleep 0.3
        "$DRIVER" type "$text_target" >/dev/null 2>&1
        # A public read issued while the window commits a refresh can come back
        # empty even though the owner value is set, so the comparison is retried
        # within a fixed bound instead of reading once.
        local poll=0
        while (( poll < 8 )); do
          AFTER_TITLE="$(field_hex title DRAFT_HEX)"
          if [[ -n "$AFTER_TITLE" && "$AFTER_TITLE" != "-" && "$AFTER_TITLE" != "$BEFORE_TITLE" ]]; then
            break
          fi
          sleep 0.3
          poll=$(( poll + 1 ))
        done
        [[ -n "$AFTER_TITLE" && "$AFTER_TITLE" != "-" && "$AFTER_TITLE" != "$BEFORE_TITLE" ]] && break
        text_attempt=$(( text_attempt + 1 ))
      done
      [[ -n "$AFTER_TITLE" && "$AFTER_TITLE" != "-" && "$AFTER_TITLE" != "$BEFORE_TITLE" ]] || \
        fail "real typing into the generated text editor did not reach the owner"
      log "step4b_text_editor_ok role=$TROLE frame='$tx $ty $tw $th' title=$(print -r -- "$AFTER_TITLE" | hex_to_text)"
    elif [[ -z "$DESKTOP_BLOCKED" ]]; then
      DESKTOP_BLOCKED="generated text editor is not exposed by the accessibility projection"
    fi
    # Real desktop press on the generated boolean editor. It is exposed with
    # the checkbox role, so the lookup asks for that role first and falls back
    # to a role-agnostic tree walk.
    FRAME="$(ax_editor_frame "提交状态编辑" "AXCheckBox")"
    if [[ "$FRAME" != "missing" && -n "$FRAME" ]]; then
      fx="$(print -r -- "$FRAME" | awk '{print $1}')"
      fy="$(print -r -- "$FRAME" | awk '{print $2}')"
      fw="$(print -r -- "$FRAME" | awk '{print $3}')"
      fh="$(print -r -- "$FRAME" | awk '{print $4}')"
      FROLE="$(print -r -- "$FRAME" | awk '{print $5}')"
      BFRAME_VERSION="$(structure_version)"
      log "step4b_boolean_probe role=$FROLE frame='$fx $fy $fw $fh' structure_version=$BFRAME_VERSION"
      BEFORE_CLICK_MARKED="$(field_hex marked DRAFT_HEX)"
      "$DRIVER" click $(( fx + fw / 2 )) $(( fy + fh / 2 )) >/dev/null 2>&1
      sleep 1.5
      AFTER_MARKED="$(field_hex marked DRAFT_HEX)"
      if [[ "$AFTER_MARKED" != "$BEFORE_CLICK_MARKED" ]]; then
        log "step4b_boolean_editor_ok role=$FROLE frame='$fx $fy $fw $fh' marked=$(print -r -- "$AFTER_MARKED" | hex_to_text)"
      else
        # Keep the reason visible instead of only failing: one more physical
        # click and one accessibility press are logged as diagnostics so the
        # next reader can tell "the press never reaches the control" from
        # "two activations per click cancel out".
        log "diag_boolean unchanged_after_click before='$(print -r -- "$BEFORE_CLICK_MARKED" | hex_to_text)' after='$(print -r -- "$AFTER_MARKED" | hex_to_text)' field='$(field_line marked)'"
        "$DRIVER" click $(( fx + fw / 2 )) $(( fy + fh / 2 )) >/dev/null 2>&1
        sleep 1.5
        log "diag_boolean second_click='$(print -r -- "$(field_hex marked DRAFT_HEX)" | hex_to_text)'"
        cjgui_ax 15 -e "tell application \"System Events\"
          set p to first process whose unix id is $APP_PID
          repeat with e in (entire contents of window 1 of p)
            try
              if (description of e) is \"提交状态编辑\" then
                perform action \"AXPress\" of e
                return \"press_sent\"
              end if
            end try
          end repeat
          return \"press_missing\"
        end tell" >/dev/null 2>&1 || true
        sleep 1.5
        log "diag_boolean axpress='$(print -r -- "$(field_hex marked DRAFT_HEX)" | hex_to_text)'"
        fail "a real press on the generated boolean editor did not reach the owner"
      fi
    else
      DESKTOP_BLOCKED="generated boolean editor is not exposed by the accessibility projection"
    fi
  else
    DESKTOP_BLOCKED="round window geometry unavailable for the desktop input driver"
  fi
else
  DESKTOP_BLOCKED="${DESKTOP_BLOCKED:-desktop input driver unavailable}"
fi
if [[ -n "$DESKTOP_BLOCKED" ]]; then
  log "BLOCKED generated_editor_desktop_input reason=$DESKTOP_BLOCKED"
fi

# --- 4c. real resize keeps the SAME declared key and the draft -------------
# The offline layout test proves the shared style vocabulary reaches the built
# geometry. This is the SAME second domain under a REAL pointer-driven resize:
# a declared constraint and font size must reach the accepted geometry, the
# window is resized by dragging its own corner, and the SAME declared key must
# still accept a NEW exact value afterwards with every other draft unchanged.
#
# The TITLE is deliberately NOT used for the continuation: the application's own
# business rule freezes it once the task has been submitted
# (`title_frozen_after_submit`), and step4b really submitted the task. The notes
# field stays editable, so the continuity mainline runs there and still proves
# the same-key resize behaviour. The freeze itself is a business refusal covered
# by the application's own test, not a delivery failure.
instance_bounds() { # instance_bounds <key> -> "x,y,w,h"
  pub generated-instances 2>/dev/null | awk -v key="$1" '$1 == "INSTANCE" && $2 == key {
    for (i = 1; i <= NF; i++) if ($i ~ /^bounds=/ && !found) { sub(/^bounds=/, "", $i); print $i; found=1 }
  }'
}
bounds_field() { # bounds_field <x,y,w,h> <index>
  print -r -- "$1" | awk -F, -v i="$2" '{print $i}'
}
cat > "$WORK/s4.txt" <<'S4'
GENERATED_UI_STRUCTURE 1
NODE 0 board4 vertical
NODE 1 icon4 image
PROPERTY 1 icon4 resource collaboration-beacon
PROPERTY 1 icon4 resourceVersion 1
PROPERTY 1 icon4 contentMode fit
PROPERTY 1 icon4 fixedWidth 56
PROPERTY 1 icon4 fixedHeight 56
NODE 1 titleEditor textInput field=title
PROPERTY 1 titleEditor label 任务标题编辑
NODE 1 bigLabel label
PROPERTY 1 bigLabel text 大字号标签
PROPERTY 1 bigLabel fontSize 24
NODE 1 smallLabel label
PROPERTY 1 smallLabel text 小字号标签
PROPERTY 1 smallLabel fontSize 12
NODE 1 stretchNote label
PROPERTY 1 stretchNote text 宽度随窗口变化
PROPERTY 1 stretchNote growX 1
NODE 1 notesEditor textInput field=notes
PROPERTY 1 notesEditor label 备注编辑
END
S4
S4_VERSION="$(structure_version)"
if [[ -z "$DESKTOP_BLOCKED" ]]; then
  AX_PID="$APP_PID"
  log "diag key_window_before_s4 focus='$(ax_window_focus)' frontmost='$(app_frontmost)'"
fi
pub generated-submit --structure-version "$S4_VERSION" --payload-file "$WORK/s4.txt" > "$WORK/submit-s4.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/submit-s4.log" || fail "the constrained/font structure was rejected"
wait_for_structure_version $((S4_VERSION + 1)) || fail "the constrained/font structure was never scene-accepted"
BOUND_ICON="$(instance_bounds icon4)"
BOUND_BIG="$(instance_bounds bigLabel)"
BOUND_SMALL="$(instance_bounds smallLabel)"
BOUND_STRETCH="$(instance_bounds stretchNote)"
BOUND_NOTES="$(instance_bounds notesEditor)"
[[ -n "$BOUND_ICON" && -n "$BOUND_BIG" && -n "$BOUND_SMALL" && -n "$BOUND_STRETCH" && -n "$BOUND_NOTES" ]] \
  || fail "the constrained/font instances are missing from the accepted read-back"
[[ "$(bounds_field "$BOUND_ICON" 3)" == "56" ]] \
  || fail "the declared fixedWidth did not reach the accepted image geometry (icon=$BOUND_ICON)"
BIG_H="$(bounds_field "$BOUND_BIG" 4)"
SMALL_H="$(bounds_field "$BOUND_SMALL" 4)"
(( BIG_H > SMALL_H )) || fail "the declared fontSize did not change the accepted label height ($BIG_H vs $SMALL_H)"
log "step4c constraint_geometry_ok icon_w=$(bounds_field "$BOUND_ICON" 3) font24_h=$BIG_H font12_h=$SMALL_H same_key=true"

# A real edit on the notes field BEFORE the resize. This is also the
# discriminator: if it fails, the failure is the scene change, not the resize.
INPUT_CONTINUATION_BLOCKED=""
TITLE_BEFORE_CONTINUATION="$(field_hex title DRAFT_HEX)"
MARKED_BEFORE_CONTINUATION="$(field_hex marked DRAFT_HEX)"
if [[ -z "$DESKTOP_BLOCKED" ]]; then
  AX_PID="$APP_PID"
  AX_APP_PATH="${ROUND_EXEC%%.app/*}.app"
  if real_generated_text_edit panel_pre_resize_edit "$DESCRIPTOR" notes "备注编辑" \
      "text field" "备注-A" notesEditor; then
    [[ "$(print -r -- "$(field_hex notes DRAFT_HEX)" | hex_to_text)" == "备注-A" ]] \
      || fail "the pre-resize notes edit is not exactly '备注-A'"
    log "step4c pre_resize_edit_ok mode='$REAL_EDIT_MODE' field=notes value='备注-A'"
  else
    INPUT_CONTINUATION_BLOCKED="post_structure_edit_not_delivered_to_owner"
    log "BLOCKED post_structure_input_continuation reason=$INPUT_CONTINUATION_BLOCKED"
  fi
fi

if [[ -z "$INPUT_CONTINUATION_BLOCKED" && -z "$DESKTOP_BLOCKED" ]]; then
  DRAFT_BEFORE_RESIZE="$(field_hex notes DRAFT_HEX)"
  FOCUS_BEFORE_RESIZE="$(field_line notes | awk '{for (i = 1; i <= NF; i++) if ($i == "FOCUS") print $(i + 1)}')"
  [[ -n "$DRAFT_BEFORE_RESIZE" && "$DRAFT_BEFORE_RESIZE" != "-" ]] \
    || fail "the notes draft did not survive the constrained/font structure change"

  # A REAL resize through the same pointer path a person uses: press the window's
  # own bottom-right corner and drag it.
  RESIZE_LOG="$WORK/second-resize.log"
  AX_PID="$APP_PID"
  make_window_key || true
  real_resize_window 140 100 > "$RESIZE_LOG" 2>&1 || true
  sleep 1.5
  RESIZED_STRETCH=""
  waited=0
  while (( waited < 20 )); do
    RESIZED_STRETCH="$(instance_bounds stretchNote)"
    if [[ -n "$RESIZED_STRETCH" && "$(bounds_field "$RESIZED_STRETCH" 3)" -gt "$(bounds_field "$BOUND_STRETCH" 3)" ]]; then
      break
    fi
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  [[ -n "$RESIZED_STRETCH" ]] || fail "the accepted geometry is not readable after the resize"
  BEFORE_W="$(bounds_field "$BOUND_STRETCH" 3)"
  AFTER_W="$(bounds_field "$RESIZED_STRETCH" 3)"
  (( AFTER_W > BEFORE_W )) \
    || fail "the real resize did not widen the growing instance ($BEFORE_W -> $AFTER_W)"
  RESIZED_ICON="$(instance_bounds icon4)"
  [[ "$(bounds_field "$RESIZED_ICON" 3)" == "56" ]] \
    || fail "the fixed constraint followed the resize instead of staying 56 (icon=$RESIZED_ICON)"
  [[ -n "$(instance_bounds notesEditor)" ]] || fail "the resize lost the accepted notes editor key"
  DRAFT_AFTER_RESIZE="$(field_hex notes DRAFT_HEX)"
  FOCUS_AFTER_RESIZE="$(field_line notes | awk '{for (i = 1; i <= NF; i++) if ($i == "FOCUS") print $(i + 1)}')"
  [[ "$DRAFT_AFTER_RESIZE" == "$DRAFT_BEFORE_RESIZE" ]] \
    || fail "the real resize lost the notes draft on the same field binding"
  [[ "$FOCUS_AFTER_RESIZE" == "$FOCUS_BEFORE_RESIZE" ]] \
    || fail "the real resize moved focus off the same binding ($FOCUS_BEFORE_RESIZE -> $FOCUS_AFTER_RESIZE)"
  [[ "$(field_hex title DRAFT_HEX)" == "$TITLE_BEFORE_CONTINUATION" ]] \
    || fail "the resize changed the frozen title draft"
  log "step4c real_resize_ok window='$(window_frame)' stretch_w=${BEFORE_W}->${AFTER_W} icon_w=56 notes_draft_kept=true focus=${FOCUS_AFTER_RESIZE} same_key=true"

  # The continuation AFTER the resize, on the SAME declared key, with an exact
  # owner read-back and every other draft unchanged.
  AFTER_RESIZE_TARGET="备注-B"
  if real_generated_text_edit panel_resize_edit "$DESCRIPTOR" notes "备注编辑" \
      "text field" "$AFTER_RESIZE_TARGET" notesEditor; then
    [[ "$(print -r -- "$(field_hex notes DRAFT_HEX)" | hex_to_text)" == "$AFTER_RESIZE_TARGET" ]] \
      || fail "the post-resize edit is not exactly '$AFTER_RESIZE_TARGET'"
    [[ "$(field_hex marked DRAFT_HEX)" == "$MARKED_BEFORE_CONTINUATION" ]] \
      || fail "the post-resize edit changed an unrelated field draft"
    [[ "$(field_hex title DRAFT_HEX)" == "$TITLE_BEFORE_CONTINUATION" ]] \
      || fail "the post-resize edit changed the frozen title draft"
    log "step4c post_resize_edit_ok mode='$REAL_EDIT_MODE' field=notes value='$AFTER_RESIZE_TARGET' other_field_unchanged=true input=real_desktop_control driver=cgevent"
  else
    INPUT_CONTINUATION_BLOCKED="post_resize_edit_not_delivered_to_owner"
    log "BLOCKED post_resize_input_continuation reason=$INPUT_CONTINUATION_BLOCKED"
  fi
fi

# --- 5. rejection family keeps the previous structure ----------------------
before_version="$(structure_version)"
cat > "$WORK/duplicate.txt" <<'R1'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 same label
PROPERTY 1 same text one
NODE 1 same label
PROPERTY 1 same text two
END
R1
pub generated-submit --structure-version "$before_version" --payload-file "$WORK/duplicate.txt" > "$WORK/dup.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/dup.log" && fail "duplicate key candidate was accepted"
grep -q 'REASON duplicate_key' "$WORK/dup.log" || fail "duplicate key rejection reason missing"
cat > "$WORK/over-limit.txt" <<'R2'
GENERATED_UI_STRUCTURE 1
NODE 0 root vertical
NODE 1 message label
PROPERTY 1 message text 这个属性值超过了第二消费者允许的字符串长度上限一百六十个字符的内容会被明确拒绝而不是截断处理它必须保持原界面可用状态继续提供服务而不是把已经接受的结构破坏掉以便后续继续使用
END
R2
pub generated-submit --structure-version "$before_version" --payload-file "$WORK/over-limit.txt" > "$WORK/limit.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/limit.log" && fail "over-limit property was accepted"
grep -q 'REASON property_too_long' "$WORK/limit.log" || fail "property limit rejection reason missing"
pub generated-submit --structure-version 0 --payload-file "$WORK/s1.txt" > "$WORK/stale.log" 2>&1 || true
grep -q 'REASON structure_version_conflict' "$WORK/stale.log" || fail "stale structure rejection missing"
[[ "$(structure_version)" == "$before_version" ]] || fail "structure version changed after rejections"
log "step5 rejections_ok version_stable=$before_version"
if [[ -n "$INPUT_CONTINUATION_BLOCKED" ]]; then
  log "BLOCKED second-consumer input continuation: $INPUT_CONTINUATION_BLOCKED"
  cat "$LOG"
  exit 3
fi
if [[ -n "$DESKTOP_BLOCKED" ]]; then
  log "BLOCKED the generated-editor desktop edit was not verified: $DESKTOP_BLOCKED"
  cat "$LOG"
  exit 3
fi
log "PASSED second-consumer generated-ui chain"

cat "$LOG"
exit 0
