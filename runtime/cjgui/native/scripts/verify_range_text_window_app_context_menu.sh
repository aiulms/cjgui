#!/usr/bin/env zsh
# Real-input context-menu acceptance for the independent range-text consumer.
# Main agent runs this serially; this source tool does not build or touch desktop.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
APP_DIR="$RUNTIME_DIR/examples/range_text_window_app"
PHAROS_ROOT="${PHAROS_ROOT:-/Users/jiangxuanyang/Desktop/Pharos Mark}"
OUTPUT_DIR="${CJGUI_RANGE_TEXT_CONTEXT_MENU_TMPDIR:-/private/tmp/cjgui-range-text-context-menu}"
SEED="E-menu-seed"
set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
if [[ -n "${CJ_GUI_SDKROOT:-}" && -d "$CJ_GUI_SDKROOT" ]]; then export SDKROOT="$CJ_GUI_SDKROOT"
else export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"; fi
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
WORK="$OUTPUT_DIR/$RUN_TAG"; mkdir -p "$WORK"
LOG="$WORK/context-menu.log"; : > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; tail -60 "$LOG"; echo "range text context menu: FAIL $*" >&2; exit 1; }
blocked() { log "BLOCKED $1"; tail -60 "$LOG"; echo "range text context menu: BLOCKED $1" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"
APP_PID=""; ROUND_DIR="$WORK/round-app"; ROUND_EXEC=""
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
CANDIDATE_EXECS=(""); CANDIDATE_DIRS=("$ROUND_DIR"); CANDIDATE_DESCS=("")
cleanup() {
  if [[ -n "$APP_PID" ]]; then cjgui_terminate_owned "$APP_PID" "" "$ROUND_EXEC" "$ROUND_DIR" || true; fi
  cjgui_reclaim_candidates log || true
}
trap cleanup EXIT

session_locked && blocked "session locked; posted input cannot be delivered"
command -v swiftc >/dev/null 2>&1 || blocked "swiftc unavailable"
prepare_desktop_driver || blocked "$INPUT_BLOCKED"
PHAROS_TOOLS="$PHAROS_ROOT/tools"
AX_PROBE="$WORK/ax_node_probe"; AX_WINDOW="$WORK/ax_owned_window"; RIGHT="$WORK/context_pointer_driver"
for item in "ax_node_probe.swift:$AX_PROBE" "ax_owned_window.swift:$AX_WINDOW" "context_pointer_driver.swift:$RIGHT"; do
  source_name="${item%%:*}"; target="${item#*:}"
  [[ -f "$PHAROS_TOOLS/$source_name" ]] || blocked "missing Pharos helper source $PHAROS_TOOLS/$source_name"
  swiftc -O "$PHAROS_TOOLS/$source_name" -o "$target" > "$WORK/${source_name%.swift}.build.log" 2>&1 \
    || blocked "could not build helper $source_name"
done
real_input_preflight || blocked "synthetic input permission refused"
NAME="CJGUIRangeTextConsumer"; SUFFIX="Cm${RUN_TAG//-/}"
ROUND_EXEC="$WORK/round-app/target/release/CJGUI Range Text Consumer.app/Contents/MacOS/${NAME}${SUFFIX}"
cjgui_prepare_app_copy "$APP_DIR" "$ROUND_DIR" "$RUNTIME_DIR" "$NAME" "$SUFFIX" \
  "org.cangjie.cjgui.range-text-consumer.example" || blocked "could not prepare app copy"
CANDIDATE_EXECS=("${NAME}${SUFFIX}")
[[ -x "$ROUND_DIR/run.sh" ]] || blocked "app copy lacks run.sh"
STDOUT_LOG="$WORK/app.log"
( cd "$ROUND_DIR" && RANGE_TEXT_INITIAL="$SEED" nohup zsh run.sh > "$STDOUT_LOG" 2>&1 & )
waited=0; ready=""
while (( waited < 900 )); do
  ready="$(grep '^RANGE_TEXT_READY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$ready" ]] && break
  sleep 2; waited=$((waited + 2))
done
[[ -n "$ready" ]] || blocked "RANGE_TEXT_READY missing"
APP_PID="$(cjgui_unique_round_pid "${NAME}${SUFFIX}" "$ROUND_DIR" || true)"
[[ -n "$APP_PID" ]] || blocked "round app pid missing"
cjgui_unique_round_owns "$APP_PID" "${NAME}${SUFFIX}" "$ROUND_DIR" || blocked "pid ownership mismatch"
AX_PID="$APP_PID"; AX_APP_PATH="$ROUND_DIR/target/release/CJGUI Range Text Consumer.app"; export AX_APP_PATH
log "step0 pid=$APP_PID ready=$ready"

ax_find() { "$AX_PROBE" "$APP_PID" find "$1" 2>/dev/null; }
ax_frame() { ax_find "$1" | sed -n 's/^frame=//p' | head -1; }
ax_value() { ax_find "$1" | awk '/^value_begin$/{p=1;next}/^value_end$/{p=0}p'; }
status_line() { ax_value range-text-status; }
status_field() {
  print -r -- "$(status_line)" | tr ' ' '\n' | awk -F= -v k="$1" '
    $1==k {print $2; exit}
    k=="v" && $0 ~ /^v[0-9]+$/ {sub(/^v/, ""); print; exit}'
}
wait_field() {
  local field="$1" expect="$2" tries="${3:-40}" i=0 got=""
  while (( i < tries )); do
    got="$(status_field "$field")"; [[ "$got" == "$expect" ]] && return 0
    sleep 0.35; i=$((i + 1))
  done
  fail "status $field expected=$expect actual=${got:-missing}"
}
field() { print -r -- "$1" | tr ' ' '\n' | awk -F= -v k="$2" '$1==k {print $2; exit}'; }
installed_count() { grep -c '^CJGUI_CONTEXT_MENU phase=installed ' "$STDOUT_LOG" 2>/dev/null || true; }
wait_installed() {
  local prior="$1" tries=40 i=0 n=""
  while (( i < tries )); do
    n="$(installed_count)"
    if [[ "$n" == <-> ]] && (( n > prior )); then grep '^CJGUI_CONTEXT_MENU phase=installed ' "$STDOUT_LOG" | tail -1; return 0; fi
    sleep 0.35; i=$((i + 1))
  done
  return 1
}
wait_end() {
  local req="$1" reason="$2" tries=40 i=0
  while (( i < tries )); do
    grep -q "^CJGUI_CONTEXT_MENU phase=ended request_id=${req} reason=${reason}$" "$STDOUT_LOG" && return 0
    sleep 0.35; i=$((i + 1))
  done
  return 1
}
verify_install() {
  python3 - "$STDOUT_LOG" "$1" "$2" "$3" "$4" "$5" <<'PY'
import re, sys
path, req, px, py, selection, version = sys.argv[1:]
px, py, version = int(px), int(py), int(version)
lines = open(path, errors="replace").read().splitlines()
def fields(line): return dict(re.findall(r"(?:^|\s)([A-Za-z_]+)=([^\s]+)", line))
menu = [fields(x) for x in lines if "CJGUI_CONTEXT_MENU phase=installed " in x and f"request_id={req}" in x]
screen = [fields(x) for x in lines if "CJGUI_CONTEXT_MENU_SCREEN " in x and f"request_id={req}" in x]
if not menu or not screen: raise SystemExit(f"installed_or_screen_log_missing request={req}")
m, s = menu[-1], screen[-1]
if m.get("selection") != selection: raise SystemExit(f"right_click_changed_selection expected={selection} actual={m.get('selection')}")
for k in ("content_version", "source_version"):
    if m.get(k) != str(version): raise SystemExit(f"ticket_{k}_mismatch expected={version} actual={m.get(k)}")
def pair(v, name):
    z=re.fullmatch(r"(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)",v or "")
    if not z: raise SystemExit(f"bad_{name}={v!r}")
    return tuple(float(a) for a in z.groups())
def rect(v, name):
    z=re.fullmatch(r"(-?\d+),(-?\d+),(-?\d+),(-?\d+)",v or "")
    if not z: raise SystemExit(f"bad_{name}={v!r}")
    return tuple(map(int,z.groups()))
host=pair(m.get("host"),"host"); origin=pair(s.get("viewport_screen"),"viewport_screen")
vp=rect(m.get("viewport"),"viewport"); layer=rect(m.get("layer_rect",m.get("rect")),"layer_rect")
if not s.get("session") or m.get("scene") != s.get("scene"): raise SystemExit("screen_identity_mismatch")
expected=(int(px-origin[0]-vp[0]),int(py-origin[1]-vp[1]))
if tuple(map(int,host)) != expected: raise SystemExit(f"host_anchor_mismatch expected={expected} actual={host}")
vx,vy,vw,vh=vp; lx,ly,lw,lh=layer
clamped=(min(max(vx+expected[0],vx),vx+vw-lw),min(max(vy+expected[1],vy),vy+vh-lh))
if (lx,ly) != clamped: raise SystemExit(f"layer_anchor_clamp_mismatch expected={clamped} actual={(lx,ly)}")
print(f"verified request={req} selection={selection} host={host} viewport_screen={origin} viewport={vp} layer_rect={layer}")
PY
}
right_body() {
  local expect_sel="$1" owner_ver="$2" prior frame x y w h px py posted line req
  frame="$(ax_frame range-text-body)"; [[ -n "$frame" ]] || blocked "body AX frame missing"
  read -r x y w h <<< "$frame"; px=$((x + w / 2)); py=$((y + h / 2))
  prior="$(installed_count)"; activate_app
  posted="$("$RIGHT" "$px" "$py" 2>&1)" || blocked "CGEvent right click failed: $posted"
  [[ "$posted" == *"posted=CGEvent.mouseEventRightMouseDown+Up"* ]] || fail "right click not confirmed: $posted"
  log "action=CGEvent.rightClick pid=$APP_PID target=range-text-body point=$px,$py result=$posted"
  line="$(wait_installed "$prior" || true)"; [[ -n "$line" ]] || fail "context menu install log timed out"
  req="$(field "$line" request_id)"; [[ "$req" == <-> ]] || fail "request_id missing: $line"
  verify_install "$req" "$px" "$py" "$expect_sel" "$owner_ver" >> "$LOG" || fail "menu install validation failed request=$req"
  log "menu_installed $line"
  print -r -- "$req $px $py"
}

# Use real keys to create a known non-empty range, then a real secondary click.
real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || true
activate_app; [[ "$(app_frontmost)" == "true" ]] || blocked "app not frontmost"
frame="$(ax_frame range-text-body)"; [[ -n "$frame" ]] || blocked "body frame unavailable"
read -r bx by bw bh <<< "$frame"
drive click $((bx + bw / 2)) $((by + bh / 2)) || blocked "could not focus editor"
drive shortcut command 123 || blocked "command-left not delivered"
drive shortcut shift 124 || blocked "shift-right not delivered"
drive shortcut shift 124 || blocked "second shift-right not delivered"
sleep 0.3
[[ "$(status_field v)" == "1" && "$(status_field bytes)" == "${#SEED}" && "$(status_field edits)" == "0" ]] || fail "seed baseline mismatch: $(status_line)"
log "step1 seed=$SEED owner_version=1 selection_expected=0,2"
reply="$(right_body 0,2 1)"; read -r req1 px1 py1 <<< "$reply"

# Click the exposed public menu item, then replace the entire seed with one
# actual keyboard edit. Version/edit counts and final owner hex are independent.
frame="$(ax_frame range-text-context-select-all || true)"; [[ -n "$frame" ]] || fail "select-all AX button missing"
read -r mx my mw mh <<< "$frame"
drive click $((mx + mw / 2)) $((my + mh / 2)) || blocked "select-all click was not delivered"
log "action=CGEvent.leftClick target=range-text-context-select-all request=$req1"
wait_end "$req1" target_or_selection_changed || fail "select-all did not retire the frozen selection ticket"
wait_field v 1 20
drive type Z || blocked "replacement character was not delivered"
wait_field v 2; wait_field bytes 1; wait_field edits 1
[[ "$(ax_value range-text-body)" == "Z" ]] || fail "select-all did not replace the whole seed"
log "step2 select_all_then_type=pass owner=Z version=2 edits=1"

# Escape must dismiss without changing the known one-character selection.
drive shortcut command 123 || blocked "command-left not delivered before Esc check"
drive shortcut shift 124 || blocked "selection key not delivered before Esc check"
sleep 0.25
reply="$(right_body 0,1 2)"; read -r req2 px2 py2 <<< "$reply"
drive key 53 || blocked "Escape key not delivered"
wait_end "$req2" escape || fail "Escape did not close request $req2"
[[ "$(status_field v)" == "2" && "$(status_field edits)" == "1" && "$(ax_value range-text-body)" == "Z" ]] || fail "Escape changed text or owner"
log "step3 escape=pass request=$req2 owner_version=2 selection=0,1"

# The outside click hits a noninteractive heading while the guard is active.
# The next real typing goes to the still-focused editor without clicking it;
# replacing Z with ! proves the old selection survived and no target activated.
reply="$(right_body 0,1 2)"; read -r req3 px3 py3 <<< "$reply"
frame="$(ax_frame range-text-heading || true)"; [[ -n "$frame" ]] || fail "heading outside target frame missing"
read -r hx hy hw hh <<< "$frame"; ox=$((hx + hw / 2)); oy=$((hy + hh / 2))
drive click "$ox" "$oy" || blocked "outside click not delivered"
log "action=CGEvent.leftClick target=range-text-heading request=$req3 point=$ox,$oy"
wait_end "$req3" outside || fail "outside click did not close request $req3"
[[ "$(status_field v)" == "2" && "$(status_field edits)" == "1" && "$(ax_value range-text-body)" == "Z" ]] || fail "outside click activated/edited underlying content"
drive type '!' || blocked "typing after outside close failed"
wait_field v 3; wait_field bytes 1; wait_field edits 2
[[ "$(ax_value range-text-body)" == "!" ]] || fail "outside close lost the previous text selection/focus"
log "step4 outside=pass request=$req3 typed_without_body_click=true owner=! version=3 edits=2"

# Close the exact round-owned normal window and compare its owner hex to the
# fixed oracle (21), with exactly two accepted owner writes.
"$AX_WINDOW" "$APP_PID" "CJGUI Range Text Consumer" close > "$WORK/close.log" 2>&1 || blocked "exact AX window close failed"
waited=0; summary=""
while (( waited < 90 )); do
  summary="$(grep '^RANGE_TEXT_SUMMARY' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
  [[ -n "$summary" ]] && break
  sleep 1; waited=$((waited + 1))
done
[[ -n "$summary" ]] || fail "owner summary did not arrive after close"
owner="$(grep '^RANGE_TEXT_OWNER_HEX' "$STDOUT_LOG" 2>/dev/null | tail -1 || true)"
[[ "$(field "$owner" hex)" == "21" && "$(field "$owner" bytes)" == "1" ]] || fail "owner hex mismatch: $owner"
[[ "$(field "$summary" version)" == "3" && "$(field "$summary" applied)" == "2" && \
   "$(field "$summary" rejected)" == "0" && "$(field "$summary" leaked_range_events)" == "0" ]] \
  || fail "owner transaction summary mismatch: $summary"
log "step5 owner=$owner summary=$summary"
log "PASS context_menu requests=$req1,$req2,$req3 owner_hex=21 version=3 applied=2"
echo "range text window context menu: PASS owner_hex=21 version=3 applied=2 log=$LOG"
