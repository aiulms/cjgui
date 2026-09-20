#!/usr/bin/env zsh
# Shared-document consumer full transfer chain on a real normal window.
#
# One current-source instance proves, in order:
#   1. external authorized write -> public read-back
#   2. window edit: real mouse click into the document editor, select-all,
#      paste through the system clipboard (keystroke composition would be
#      swallowed by the active CJK input method) -> public read-back
#   3. external authorized change
#   4. the window editor DISPLAYS the external change, then the window
#      edits again -> public read-back
#   5. declared transfer endpoints through real Cmd-C / Cmd-V on different
#      selections: copy the whole document, collapse the caret, append
#   6. final external authorized change, displayed by the window
#
# Instance ownership (A1): each round copies the example app into its own
# output directory and gives it a unique bundle name/identifier, launches
# it, records the real application PID (verified against the executable
# path), addresses the app through that PID only, and cleans up gracefully
# (AX close first, then signals only to the re-verified PID).  The scripts
# never kill by process name, so a user instance with a similar name cannot
# be touched.  The system clipboard is snapshot-guarded: the original
# snapshot is taken before the first write and only restored while the
# current clipboard still matches this round's last write.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/lib_cjgui_instance.sh"

# The human half of this chain (real drag/typing in two windows) cannot be
# delivered while the session is locked: the presses reach no window and the
# chains below would report product FAILures. Report the measured lock as
# BLOCKED (exit 3) so callers - including verify_instance_isolation.sh, which
# propagates this child's verdict - classify the environment correctly.
LOCK_STATE="$(ioreg -n Root -d 1 2>/dev/null | grep -o '"CGSSessionScreenIsLocked"=[^,}]*' | head -1 | awk -F= '{print $2}' || true)"
LOCK_STATE="${LOCK_STATE//[[:space:]]/}"
if [[ "$LOCK_STATE" == "Yes" ]]; then
  echo "shared document transfer chain: BLOCKED the session is locked (CGSSessionScreenIsLocked=Yes); the human drag/typing steps cannot be delivered" >&2
  exit 3
fi
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
OUTPUT_DIR="${CJGUI_SHARED_DOCUMENT_TRANSFER_CHAIN_TMPDIR:-/private/tmp/cjgui-shared-document-transfer-chain}/$RUN_TAG"
CGTOOL="$OUTPUT_DIR/cgtool"
APP_EXEC_NAME="CJGUISharedDocument$RUN_TAG"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u

if [[ -n "${CJ_GUI_SDKROOT:-}" ]]; then
  SDKROOT_PATH="$CJ_GUI_SDKROOT"
elif [[ -n "${SDKROOT:-}" && -d "$SDKROOT" ]]; then
  SDKROOT_PATH="$SDKROOT"
else
  SDKROOT_PATH="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
export SDKROOT="$SDKROOT_PATH"

mkdir -p "$OUTPUT_DIR"
STDOUT_LOG="$OUTPUT_DIR/app-stdout.log"
CHAIN_LOG="$OUTPUT_DIR/chain.log"
AX_LOG="$OUTPUT_DIR/ax.log"
CLIENT="$RUNTIME_DIR/shared_operation_core/client.py"
: > "$CHAIN_LOG"; : > "$AX_LOG"

log() { print -r -- "$*" >> "$CHAIN_LOG"; }
fail() { log "FAIL $*"; cat "$CHAIN_LOG"; CHAIN_STATUS=1; exit 1; }
# A verified precondition we do not own (for example a user copy racing the
# transfer step) stops only the dependent step; the caller classifies exit 3
# as BLOCKED instead of turning it into a product failure.
blocked() { log "BLOCKED $*"; cat "$CHAIN_LOG"; CHAIN_STATUS=3; exit 3; }

# --- per-round application identity ---------------------------------------
APP_DIR="$OUTPUT_DIR/app"
mkdir -p "$APP_DIR"
cp -R "$RUNTIME_DIR/examples/shared_document_window_app/src" "$APP_DIR/src"
cp "$RUNTIME_DIR/examples/shared_document_window_app/cjpm.toml" "$APP_DIR/cjpm.toml"
cp "$RUNTIME_DIR/examples/shared_document_window_app/cjgui_macos_app.sh" "$APP_DIR/cjgui_macos_app.sh"
python3 - "$APP_DIR" "$RUNTIME_DIR" "$RUN_TAG" <<'PYID'
import re
import sys
app, runtime, tag = sys.argv[1:4]
toml = open(f"{app}/cjpm.toml").read()
toml = re.sub(r'cjgui = \{ path = "[^"]+" \}', f'cjgui = {{ path = "{runtime}" }}', toml)
toml = re.sub(r'cjgui_shared_operation_core = \{ path = "[^"]+" \}',
              f'cjgui_shared_operation_core = {{ path = "{runtime}/shared_operation_core" }}', toml)
open(f"{app}/cjpm.toml", "w").write(toml)
m = open(f"{app}/cjgui_macos_app.sh").read()
m = m.replace("CJGUISharedDocument", f"CJGUISharedDocument{tag}")
m = m.replace("org.cangjie.cjgui.shared-document.example",
              f"org.cangjie.cjgui.shared-document.e2e.{tag}")
open(f"{app}/cjgui_macos_app.sh", "w").write(m)
PYID
cat > "$APP_DIR/run.sh" <<RUNSH
#!/usr/bin/env zsh
exec zsh "$RUNTIME_DIR/scripts/run_macos_application.sh" "$APP_DIR/cjgui_macos_app.sh" "\$@"
RUNSH
chmod +x "$APP_DIR/run.sh"

# --- build the real-mouse driver ------------------------------------------
cat > "$OUTPUT_DIR/cgtool.swift" <<'SWIFT'
import CoreGraphics
import Foundation
func post(_ type: CGEventType, _ point: CGPoint, button: CGMouseButton = .left) {
    let event = CGEvent(mouseEventSource: nil, mouseType: type, mouseCursorPosition: point, mouseButton: button)
    event?.post(tap: .cghidEventTap)
    usleep(30_000)
}
let args = CommandLine.arguments
guard args.count >= 2 else { exit(2); }
switch args[1] {
case "click":
    guard args.count == 4, let x = Double(args[2]), let y = Double(args[3]) else { exit(2); }
    let p = CGPoint(x: x, y: y)
    post(.mouseMoved, p)
    post(.leftMouseDown, p)
    usleep(60_000)
    post(.leftMouseUp, p)
default:
    exit(2)
}
SWIFT
swiftc "$OUTPUT_DIR/cgtool.swift" -o "$CGTOOL" 2>> "$AX_LOG" || fail "cgtool build failed"

# --- launch and identify the real application PID --------------------------
DESCRIPTOR=""
APP_PID=""
ROUND_EPOCH="$(date +%s)"
# The round's own descriptor is the decisive same-instance binding. It must be
# resolved through the shared identity library, not through lsof alone: this
# descriptor is a plain connection file that the application publishes but does
# not hold open, so `lsof -t` reports no owner and an lsof-only check resolves
# to "nobody owns this instance" -- which both failed the launch handshake and
# (worse) left the running instance behind because cleanup had no PID to
# reclaim. The library falls back to "the single process whose command line
# carries this round's executable name and directory, started at or after this
# round began".
pid_owns_descriptor() { # pid_owns_descriptor <pid> [descriptor]
  cjgui_pid_owns "$1" "${2:-${DESCRIPTOR:-}}" "$APP_EXEC_NAME" "$APP_DIR"
}
descriptor_owner_pid() { # descriptor_owner_pid <descriptor>
  cjgui_descriptor_owner_pid "$1" "$APP_EXEC_NAME" "$APP_DIR" "$ROUND_EPOCH"
}
launch_app() {
  local bound=""
  bound="$(cjgui_launch_bound "$APP_DIR" run.sh \
    'CJGUI_SHARED_DOCUMENT_READY DESCRIPTOR_PATH' "$APP_EXEC_NAME" "$STDOUT_LOG" 90 \
    --with-connection || true)"
  APP_PID="${bound%% *}"
  DESCRIPTOR="${bound#* }"
  [[ -n "$APP_PID" && "$DESCRIPTOR" != "$bound" ]] || return 1
  pid_owns_descriptor "$APP_PID" "$DESCRIPTOR" || return 1
  printf '%s\n' "$APP_PID" > "$OUTPUT_DIR/app.pid"
  log "launch_app owner_pid=$APP_PID descriptor=$DESCRIPTOR exec=$APP_EXEC_NAME"
  return 0
}

# Only this round's verified PID is ever signalled; re-check the descriptor
# ownership and executable identity before each signal so a recycled PID, a
# user instance, or a stray process in the same directory cannot be hit.
pid_is_ours() {
  [[ -n "${APP_PID:-}" ]] && pid_owns_descriptor "$APP_PID" "${DESCRIPTOR:-}"
}
# A failed handshake must still not leak: resolve the round-unique instance by
# executable name plus directory (this round's own copy) and reclaim it.
resolve_round_pid() {
  [[ -n "${APP_PID:-}" ]] && return 0
  APP_PID="$(descriptor_owner_pid "${DESCRIPTOR:-}" 2>/dev/null || true)"
  [[ -n "$APP_PID" ]] && return 0
  APP_PID="$(cjgui_unique_round_pid "$APP_EXEC_NAME" "$APP_DIR" 2>/dev/null || true)"
  [[ -n "$APP_PID" ]]
}
cleanup() {
  if [[ -n "${KEEP_ON_FAIL:-}" && "${CHAIN_STATUS:-0}" != "0" ]]; then
    restore_clipboard || true
    log "cleanup skipped (KEEP_ON_FAIL); app pid=${APP_PID:-none}"
    return
  fi
  restore_clipboard || true
  if ! pid_is_ours; then
    # The handshake may have failed before a PID was published. Resolve by
    # round identity so the instance cannot survive the round.
    if resolve_round_pid; then
      log "cleanup reclaimed unresolved instance pid=$APP_PID"
    fi
  fi
  if pid_is_ours && [[ -z "${CHAIN_SKIP_GRACEFUL:-}" ]]; then
    osascript -e "tell application \"System Events\"
      set p to (first process whose unix id is $APP_PID)
      try
        perform action \"AXPress\" of (first button of window 1 of p whose subrole is \"AXCloseButton\")
      end try
    end tell" >> "$AX_LOG" 2>&1 || true
    sleep 2
  fi
  if pid_is_ours; then
    log "graceful close timed out; signalling verified pid $APP_PID"
    kill "$APP_PID" 2>/dev/null || true
    sleep 2
  fi
  if pid_is_ours; then
    log "pid $APP_PID still alive after TERM; sending KILL"
    kill -9 "$APP_PID" 2>/dev/null || true
    sleep 1
  fi
  if pid_is_ours; then
    log "cleanup instance still alive"
  else
    log "cleanup instance closed"
  fi
  # Final safety net: every signal above is gated on the descriptor-based proof,
  # so a descriptor that was replaced, or a handshake that stopped halfway,
  # leaves `pid_is_ours` false forever and the round's copy alive. Reclaim by the
  # round-unique executable name plus the per-round directory, which can never
  # select a user instance.
  if ! pid_is_ours; then
    local fallback
    fallback="$(cjgui_unique_round_pid "$APP_EXEC_NAME" "$APP_DIR" 2>/dev/null || true)"
    if [[ -n "$fallback" ]]; then
      log "cleanup reclaiming round instance pid=$fallback by unique exec+dir"
      cjgui_terminate_owned "$fallback" "" "$APP_EXEC_NAME" "$APP_DIR" || true
    fi
  fi
}
# --- clipboard guard plumbing (declared before the trap) ------------------
# cleanup can fire before the guard binary is built (for example when the
# launch handshake fails), so the restore helper and its paths exist as soon as
# the trap is installed; the snapshot itself still starts only once the window
# is up.
CLIPBOARD_GUARD=""
CLIPBOARD_GUARD_SAVE=""
CLIPBOARD_GUARD_EXPECTED=""
GUARD_ACTIVE=""
restore_clipboard() {
  if [[ -n "${GUARD_ACTIVE:-}" && -n "${CLIPBOARD_GUARD:-}" && -x "${CLIPBOARD_GUARD:-}" ]]; then
    local out
    # Capture the guard's own verdict: `state=foreign` is only printed when the
    # live pasteboard no longer matches the value this round itself last wrote,
    # i.e. when an external write is actually observed. That observation is
    # published on stdout as well as in the chain log so the driver can
    # attribute a post-run mismatch from evidence instead of assuming a user
    # copy raced the run.
    out="$("$CLIPBOARD_GUARD" restore-if-current "$CLIPBOARD_GUARD_SAVE" "$CLIPBOARD_GUARD_EXPECTED" 2>&1 || true)"
    print -r -- "$out" >> "$AX_LOG"
    if [[ "$out" == *"state=foreign"* ]]; then
      print -r -- "clipboard_guard_observed_foreign $(print -r -- "$out" | tail -1)"
      log "clipboard_guard_observed_foreign $(print -r -- "$out" | tail -1)"
    fi
    GUARD_ACTIVE=""
  fi
}
trap cleanup EXIT

launch_app || fail "app did not become ready"
log "launched descriptor=$DESCRIPTOR pid=$APP_PID exec=$APP_EXEC_NAME"

# --- clipboard guard (snapshot; restore only while untouched) -------------
CLIPBOARD_GUARD="$OUTPUT_DIR/cjgui_clipboard_guard"
clang -fobjc-arc -framework AppKit "$RUNTIME_DIR/native/tests/clipboard_guard.m" -o "$CLIPBOARD_GUARD" 2>> "$AX_LOG" \
  || fail "clipboard guard build failed"
CLIPBOARD_GUARD_SAVE="$OUTPUT_DIR/clipboard-before.plist"
CLIPBOARD_GUARD_EXPECTED="$OUTPUT_DIR/clipboard-expected.plist"
"$CLIPBOARD_GUARD" start-text "$CLIPBOARD_GUARD_SAVE" "$CLIPBOARD_GUARD_EXPECTED" >> "$AX_LOG" 2>&1
GUARD_ACTIVE=1

# --- public client helpers ------------------------------------------------
pub() { python3 "$CLIENT" "$DESCRIPTOR" "$@"; }
utf8len() { python3 -c 'import sys; print(len(sys.argv[1].encode("utf-8")))' "$1"; }
utf8hex() { python3 -c 'import sys; print(sys.argv[1].encode("utf-8").hex().upper())' "$1"; }
doc_version() {
  local out
  out="$(pub read-range 7101 0 0 0 2>/dev/null || true)"
  print -r -- "$out" | awk '/^VERSION /{print $2; exit}'
}
expect_doc() { # <expected_text>
  local len v out hex want attempt
  len="$(utf8len "$1")"
  want="$(utf8hex "$1")"
  for attempt in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    v="$(doc_version)"
    out="$(pub read-range 7101 0 "$len" "$v" 2>/dev/null || true)"
    [[ "$out" == *'AVAILABLE true'* ]] || { sleep 0.5; continue; }
    hex="$(print -r -- "$out" | awk '/^CONTENT_UTF8_HEX /{print $3}')"
    if [[ "$hex" != "$want" ]]; then
      local gotText
      gotText="$(python3 -c 'import sys; print(bytes.fromhex(sys.stdin.read().strip()).decode("utf-8","replace"))' "$hex" 2>/dev/null || true)"
      fail "doc v$v content mismatch: got '${gotText:0:80}'"
    fi
    log "content_ok docv$v len=$len"
    return 0
  done
  fail "read never stabilized (wanted len=$len)"
}
external_replace_all() { # <expected_text> <new_text> <log-name>
  local v len
  v="$(doc_version)"
  len="$(utf8len "$1")"
  pub invoke "$v" REPLACE_RANGE --target 7101 --arg start=INTEGER:0 --arg end=INTEGER:$len \
    --arg text=STRING:"$2" > "$OUTPUT_DIR/$3" 2>&1
  grep -q '^APPLIED true' "$OUTPUT_DIR/$3" || fail "external replace ($3) not applied"
}

# --- AX helpers (addressed by this round's PID) ---------------------------
front() {
  osascript -e "tell application \"System Events\"
  set p to (first process whose unix id is $APP_PID)
  set frontmost of p to true
  perform action \"AXRaise\" of window 1 of p
end tell" >> "$AX_LOG" 2>&1
  sleep 0.4
}
ax_key() { osascript -e "tell application \"System Events\" to $1" >> "$AX_LOG" 2>&1; sleep 0.25; }
press_button() {
  osascript -e "tell application \"System Events\"
  set p to (first process whose unix id is $APP_PID)
  click button \"$1\" of window 1 of p
end tell" >> "$AX_LOG" 2>&1
  sleep 0.5
}
click_editor() {
  local xy x y
  xy="$(osascript -e "tell application \"System Events\"
  set p to (first process whose unix id is $APP_PID)
  set e to text field \"说明文档\" of window 1 of p
  set pos to position of e
  set sz to size of e
  return ((item 1 of pos) + 30) & \" \" & ((item 2 of pos) + ((item 2 of sz) div 2))
end tell" 2>/dev/null | tr -d ',' || true)"
  x="${${=xy}[1]}"
  y="${${=xy}[-1]}"
  [[ -n "$x" && -n "$y" ]] || fail "no coordinates for the editor"
  "$CGTOOL" click "$x" "$y" >> "$AX_LOG" 2>&1
  sleep 0.4
}
editor_value() {
  osascript -e "tell application \"System Events\"
  set p to (first process whose unix id is $APP_PID)
  set e to text field \"说明文档\" of window 1 of p
  return (value of attribute \"AXValue\" of e) as string
end tell" 2>/dev/null || true
}
window_replace_all() {
  front
  click_editor
  osascript -e "set the clipboard to \"$1\"" >> "$AX_LOG" 2>&1
  "$CLIPBOARD_GUARD" snapshot "$CLIPBOARD_GUARD_EXPECTED" >> "$AX_LOG" 2>&1
  ax_key 'keystroke "a" using command down'
  ax_key 'keystroke "v" using command down'
  sleep 1
}

front

# --- 1. external authorized write at the document end --------------------
C0='第一行：把实际输入交给仓颉文档。
第二行：选区使用 UTF-8 字节位置。
第三行：emoji 🙂 不会被拆开。'
C0_BYTES="$(utf8len "$C0")"
C1="${C0}X1"
pub invoke 0 INSERT_TEXT --target 7101 --arg offset=INTEGER:$C0_BYTES --arg text=STRING:"X1" \
  > "$OUTPUT_DIR/ext-write-v1.log" 2>&1
grep -q '^APPLIED true' "$OUTPUT_DIR/ext-write-v1.log" || fail "external seed not applied"
expect_doc "$C1"
log "step1 external_write_ok"

# --- 2. window edit through the editor (paste replaces all) --------------
window_replace_all "W2"
expect_doc "W2"
log "step2 window_edit_ok"

# --- 3. external authorized change ---------------------------------------
external_replace_all "W2" "W2X3" "ext-write-v3.log"
expect_doc "W2X3"
log "step3 external_change_ok"

# --- 4. the window displays the external change, then edits again --------
EDITOR_VALUE="$(editor_value)"
[[ "$EDITOR_VALUE" == W2X3* ]] || fail "window did not display external change: '$EDITOR_VALUE'"
log "step4a external_change_displayed"
window_replace_all "W4"
expect_doc "W4"
log "step4b window_edit_again_ok"

# --- 5. transfer endpoints with real Cmd-C / Cmd-V -----------------------
front
click_editor
ax_key 'keystroke "a" using command down'   # select the whole document
press_button "复制选区"
# The clipboard value before the copy is the baseline that separates "our copy
# never landed" (unchanged) from "something else wrote the pasteboard" (changed
# to a value that is not our copy). Neither is assumed to be a user race.
CLIP_BEFORE_COPY="$(osascript -e 'the clipboard as text' 2>/dev/null || true)"
ax_key 'keystroke "c" using command down'   # the button only arms the endpoint
sleep 0.4
COPIED_EXPECTED="W4"
CLIP_NOW="$(osascript -e 'the clipboard as text' 2>/dev/null || true)"
if [[ "$CLIP_NOW" != "$COPIED_EXPECTED" ]]; then
  if [[ "$CLIP_NOW" == "$CLIP_BEFORE_COPY" ]]; then
    # No external write was observed: the copy simply did not take effect (or
    # the app copied the wrong content). That is a real failure, not a race.
    fail "the declared transfer copy did not reach the clipboard: unchanged before/after Cmd-C ('$CLIP_NOW'), expected '$COPIED_EXPECTED'"
  fi
  # The pasteboard changed without this round writing it: an external write is
  # observed, so this is a verified environment precondition (BLOCKED). The
  # user's value is preserved and the dependent paste step is skipped.
  blocked "clipboard_changed_by_observed_external_write before='$CLIP_BEFORE_COPY' now='$CLIP_NOW' expected='$COPIED_EXPECTED' user_value_preserved"
fi
"$CLIPBOARD_GUARD" snapshot "$CLIPBOARD_GUARD_EXPECTED" >> "$AX_LOG" 2>&1
click_editor
ax_key 'key code 125 using command down'    # Cmd+Down: caret to the end
press_button "粘贴到选区"
ax_key 'keystroke "v" using command down'
sleep 1.2
expect_doc "W4W4"
# Adopt the app-side Cmd-C write as this round's own only while the clipboard
# still holds exactly that copy. Any other value (a user copy that raced us)
# stays untouched and unnamed: cleanup then refuses to restore over it.
CLIP_AFTER_PASTE="$(osascript -e 'the clipboard as text' 2>/dev/null || true)"
if [[ "$CLIP_AFTER_PASTE" == "$COPIED_EXPECTED" ]]; then
  "$CLIPBOARD_GUARD" snapshot "$CLIPBOARD_GUARD_EXPECTED" >> "$AX_LOG" 2>&1
else
  log "note clipboard_after_paste_foreign text='$CLIP_AFTER_PASTE' (not adopting)"
fi
log "step5 transfer_paste_ok"

if [[ -n "${CHAIN_FORCE_FAIL_AFTER_COPY:-}" ]]; then
  # Test-only injection: the isolation driver runs this path to verify that a
  # failed tested run still leaves the user's real clipboard intact.
  fail "forced failure after copy (test-only injection CHAIN_FORCE_FAIL_AFTER_COPY)"
fi

# --- 6. final external change, displayed by the window -------------------
external_replace_all "W4W4" "X6" "ext-write-v6.log"
expect_doc "X6"
EDITOR_VALUE="$(editor_value)"
[[ "$EDITOR_VALUE" == X6* ]] || fail "window did not display final external change: '$EDITOR_VALUE'"
log "step6 final_external_displayed"
restore_clipboard
log "PASSED all steps"

cat "$CHAIN_LOG"
exit 0
