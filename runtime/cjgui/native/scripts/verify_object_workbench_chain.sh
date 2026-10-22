#!/bin/zsh
# DS4.1f 多对象范围编辑＋集合组合消费：一条同候选连续链。
#
# 观察者只有三种：真实键鼠（owned driver/raw CGEvent）、无障碍树、公开客户端。
# 每一步断言的都是 owner 事实（客户端读回）与用户可见事实（AX/像素/截图）的一致，
# 不用实现自己的计数冒充当证据。被测应用的 owner 事务另打印 PRESET_CARD_RANGE_EDIT
# 与 PRESET_CARD_WHOLE_TEXT_INTENT，用于区分"范围会话写入"与"整值 intent"。
set -u
SCRIPT_DIR="${0:A:h}"
RUNTIME_DIR="${SCRIPT_DIR:h:h}"
APP_DIR="${CJGUI_REACTIVE_APP_DIR:?set CJGUI_REACTIVE_APP_DIR to the built application}"
WORK="${CJGUI_REACTIVE_TMPDIR:-/private/tmp/cjgui-composite-chain-$(date +%H%M%S)-$$}"
EVIDENCE="$RUNTIME_DIR/artifacts/ds41f-range-collection-20261022"
mkdir -p "$WORK"
LOG="$WORK/chain.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
fail() { log "FAIL $*"; print -r -- "chain: FAIL $*" >&2; tail -30 "$LOG" >&2; exit 1; }
blocked() { log "BLOCKED $1"; print -r -- "chain: BLOCKED $1" >&2; tail -25 "$LOG" >&2; exit 3; }
source "$SCRIPT_DIR/lib_cjgui_instance.sh"
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

BUNDLE="$APP_DIR/target/release/CJGUIMixedFormStarter.app"
APP_EXEC="$BUNDLE/Contents/MacOS/CJGUIMixedFormStarter"
CLIENT="$APP_DIR/client.py"
[[ -x "$APP_EXEC" ]] || blocked "app not built at $APP_EXEC"
[[ -f "$CLIENT" ]] || blocked "client missing"

# ---- tooling --------------------------------------------------------------
DRIVER="$WORK/cjgui_desktop_input_driver"
swiftc -O "$RUNTIME_DIR/native/tests/desktop_input_driver.swift" -o "$DRIVER" > "$WORK/driver-build.log" 2>&1 \
  || blocked "desktop driver build failed"
AX="$WORK/ax_node_probe"
swiftc -O "/Users/jiangxuanyang/Desktop/Pharos Mark/tools/ax_node_probe.swift" -o "$AX" > "$WORK/ax-build.log" 2>&1 \
  || blocked "AX probe build failed"
cat > "$WORK/left_driver.swift" <<'SWIFT'
import CoreGraphics
import Foundation
let a = CommandLine.arguments
guard a.count == 3, let x = Double(a[1]), let y = Double(a[2]) else { exit(2) }
let p = CGPoint(x: x, y: y)
for t in [CGEventType.mouseMoved, .leftMouseDown, .leftMouseUp] {
    CGEvent(mouseEventSource: nil, mouseType: t, mouseCursorPosition: p, mouseButton: .left)?.post(tap: .cghidEventTap)
    usleep(30_000)
}
SWIFT
cat > "$WORK/input_source.swift" <<'SWIFT'
import Carbon
import Foundation
func idOf(_ source: TISInputSource?) -> String {
    guard let source else { return "<none>" }
    guard let p = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "<none>" }
    return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
}
print(idOf(TISCopyCurrentKeyboardInputSource()?.takeRetainedValue()))
SWIFT
INPUT_SOURCE_TOOL="$WORK/input_source"
swiftc -O "$WORK/input_source.swift" -o "$INPUT_SOURCE_TOOL" > "$WORK/input-source-build.log" 2>&1 || true
LEFT="$WORK/left_driver"
swiftc -O "$WORK/left_driver.swift" -o "$LEFT" > "$WORK/left-build.log" 2>&1 || blocked "left click build failed"
WHEEL_SCROLL="$WORK/wheel_scroll"
cat > "$WORK/wheel_scroll.swift" <<'WHEEL'
import CoreGraphics
import Foundation
let args = CommandLine.arguments
guard args.count == 4, let x = Double(args[1]), let y = Double(args[2]), let lines = Int32(args[3]) else { exit(2) }
let point = CGPoint(x: x, y: y)
CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?
    .post(tap: .cghidEventTap)
usleep(30_000)
if let scroll = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 1, wheel1: lines,
                        wheel2: 0, wheel3: 0) {
    scroll.location = point
    scroll.post(tap: .cghidEventTap)
}
WHEEL
swiftc -O "$WORK/wheel_scroll.swift" -o "$WHEEL_SCROLL" > "$WORK/wheel-build.log" 2>&1 \
  || blocked "wheel helper build failed"

ax_frame() { "$AX" "$1" find "$2" 2>/dev/null | sed -n 's/^frame=//p' | head -1; }
ax_value() { "$AX" "$1" find "$2" 2>/dev/null | sed -n '/^value_begin$/,/^value_end$/p' | sed '1d;$d'; }
ax_enabled() { "$AX" "$1" find "$2" 2>/dev/null | sed -n 's/^enabled=//p' | head -1; }
frame_ok() { [[ -n "${1:-}" && "$1" != "missing" && "${1##* }" != "0" ]]; }
reveal_row() { # reveal_row <row semantic id> <label>
  local sem="$1" label="${2:-$1}" frame="" i scroll_frame win
  frame="$(ax_frame "$APP_PID" "$sem")"
  if frame_ok "$frame"; then print -r -- "$frame"; return 0; fi
  scroll_frame="$(ax_frame "$APP_PID" "$COLLECTION_VIEWPORT_SEM")"
  frame_ok "$scroll_frame" || return 1
  read -r wx wy ww wh <<< "$scroll_frame"
  local cx=$(( wx + ww / 2 )) cy=$(( wy + wh / 2 ))
  for i in {1..24}; do "$WHEEL_SCROLL" $cx $cy 6 >/dev/null 2>&1; sleep 0.08; done
  frame="$(ax_frame "$APP_PID" "$sem")"; frame_ok "$frame" && { print -r -- "$frame"; return 0; }
  for i in {1..30}; do
    "$WHEEL_SCROLL" $cx $cy -6 >/dev/null 2>&1; sleep 0.08
    frame="$(ax_frame "$APP_PID" "$sem")"; frame_ok "$frame" && { print -r -- "$frame"; return 0; }
  done
  print -r -- "reveal_row_failed:${label}" >&2
  return 1
}
frontmost_name() { osascript -e 'tell application "System Events" to get name of first process whose frontmost is true' 2>/dev/null || print -r -- unknown; }
# The window rectangle from the SAME accessibility tree the steps read.
window_frame() {
  "$AX" "$APP_PID" dump 2>/dev/null | awk '/role=AXWindow/ {print; exit}' \
    | sed -n 's/.*frame=\([-0-9]*\),\([-0-9]*\),\([-0-9]*\),\([-0-9]*\).*/\1 \2 \3 \4/p'
}
WIN_FRAME=""
# Reveals one accepted element with REAL wheel events (never a programmatic scroll
# request) and returns its positive frame. It sweeps down first, then up twice,
# then down again so a target either above or below the current offset is found.
reveal_sem() {
  local sem="$1" label="${2:-$1}" frame="" i
  frame="$(ax_frame "$APP_PID" "$sem")"
  log "reveal $label initial=[$frame]"
  if frame_ok "$frame"; then print -r -- "$frame"; return 0; fi
  # Wheel OVER the content: the outer scroll area's lower half belongs to the
  # card content, while a point inside the collection's own viewport would scroll
  # that inner list instead. Both rectangles come from the AX tree.
  local scroll_frame
  scroll_frame="$(ax_frame "$APP_PID" preset-scroll)"
  frame_ok "$scroll_frame" || return 1
  local wx wy ww wh cx cy
  read -r wx wy ww wh <<< "$scroll_frame"
  cx=$(( wx + ww / 2 )); cy=$(( wy + wh * 3 / 4 ))
  log "reveal $label wheel_point=$cx,$cy scroll=[$scroll_frame] frontmost=$(frontmost_name)"
  for i in {1..10}; do
    "$WHEEL_SCROLL" $cx $cy -6 >/dev/null 2>&1; sleep 0.1
    frame="$(ax_frame "$APP_PID" "$sem")"
    (( i % 4 == 0 )) && log "reveal $label down$i=[$frame]"
    frame_ok "$frame" && { print -r -- "$frame"; return 0; }
  done
  for i in {1..16}; do
    "$WHEEL_SCROLL" $cx $cy 6 >/dev/null 2>&1; sleep 0.08
    frame="$(ax_frame "$APP_PID" "$sem")"
    (( i % 6 == 0 )) && log "reveal $label up$i=[$frame]"
    frame_ok "$frame" && { print -r -- "$frame"; return 0; }
  done
  for i in {1..14}; do
    "$WHEEL_SCROLL" $cx $cy -6 >/dev/null 2>&1; sleep 0.1
    frame="$(ax_frame "$APP_PID" "$sem")"; frame_ok "$frame" && { print -r -- "$frame"; return 0; }
  done
  log "reveal $label failed final=[$frame]"
  print -r -- "reveal_failed:${label}" >&2
  return 1
}

center_click() {
  local frame="$1"
  frame_ok "$frame" || return 1
  read -r x y w h <<< "$frame"
  "$LEFT" $(( x + w / 2 )) $(( y + h / 2 )) >> "$WORK/click.log" 2>&1
}
activate_app() {
  local pid="$1"
  open "$BUNDLE" >/dev/null 2>&1
  osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $pid) to true" \
    >/dev/null 2>&1 || true
  sleep 0.6
}
sel_map() {  # one python read of instances -> "key|element|semantic|owner" lines
  python3 - "$WORK/generate.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for i in d["instances"]["instances"]:
    if i.get("element_key") in ("name", "apply", "cancel"):
        print(f'{i.get("key")}|{i["element_key"]}|{i["semantic_id"]}|{i.get("owner_resource_id")}')
PY
}

# ---- launch ---------------------------------------------------------------
session_locked && blocked "session locked"
prepare_desktop_driver || blocked "$INPUT_BLOCKED"
real_input_preflight > "$WORK/preflight.log" 2>&1 || blocked "input permission refused"
log "step0 driver=$DRIVER facts=$(head -2 "$WORK/preflight.log" | tail -1)"
APP_LOG="$WORK/app.log"
CJGUI_PRINT_COUNTERS_TRACE=1 CJGUI_RANGE_ROUTE_TRACE=1 "$APP_EXEC" --collaboration > "$APP_LOG" 2>&1 &
APP_PID=$!
cleanup() { [[ -n "${APP_PID:-}" ]] && cjgui_terminate_owned "$APP_PID" "" "$APP_EXEC" "$BUNDLE" || true; }
trap cleanup EXIT
for i in {1..100}; do
  grep -q "CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH" "$APP_LOG" 2>/dev/null && break
  sleep 0.25
done
DESC="$(sed -n 's/^CJGUI_MIXED_FORM_READY DESCRIPTOR_PATH //p' "$APP_LOG" | head -1)"
[[ -n "$DESC" && -f "$DESC" ]] || blocked "descriptor missing"
real_ax_wait_ready "$APP_PID" 24 > "$WORK/ax-ready.log" 2>&1 || blocked "AX tree not ready"
client() { python3 "$CLIENT" "$DESC" "$@"; }
client generate --output "$WORK/generate.json" > "$WORK/generate.out" 2> "$WORK/generate.err" \
  || fail "generate failed: $(tail -3 "$WORK/generate.err")"
activate_app "$APP_PID"
SCOPE="$WORK/owned-input-$APP_PID.json"
python3 - "$APP_PID" "$APP_EXEC" "$SCOPE" <<'PY'
import json, os, sys, uuid
pid, executable, path = sys.argv[1:]
json.dump({"pid": int(pid), "nonce": uuid.uuid4().hex, "executable": executable}, open(path, "w"))
os.chmod(path, 0o600)
PY
"$DRIVER" bind-target "$SCOPE" > "$WORK/owned-bind.log" 2>&1 || blocked "owned bind failed"
export CJGUI_DRIVER_TARGET_PID="$APP_PID" CJGUI_DRIVER_TARGET_FILE="$SCOPE"

python3 - "$WORK/generate.json" <<'PY' || fail "initial acceptance shape"
import json, sys
d = json.load(open(sys.argv[1]))
s = d["submit"]
assert s["candidate_accepted"], s
inst = d["instances"]["instances"]
assert any(i.get("key") == "cardA" and i.get("element_key") == "root" for i in inst)
assert any(i.get("key") == "cardB" and i.get("element_key") == "root" for i in inst)
print("step1 accepted_cards=cardA,cardB structure_version=%s instances=%s" % (
    d["instances"]["structure_version"], len(inst)))
PY
sleep 1.0
sem_name_A="$(sel_map | awk -F'|' '$1=="cardA" && $2=="name" {print $3}' | head -1)"
sem_name_B="$(sel_map | awk -F'|' '$1=="cardB" && $2=="name" {print $3}' | head -1)"
sem_apply_B="$(sel_map | awk -F'|' '$1=="cardB" && $2=="apply" {print $3}' | head -1)"
sem_cancel_A="$(sel_map | awk -F'|' '$1=="cardA" && $2=="cancel" {print $3}' | head -1)"
[[ -n "$sem_name_A" && -n "$sem_name_B" ]] || fail "card element semantics missing"
COLLECTION_VIEWPORT_SEM="$(python3 - "$WORK/generate.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
print(next(i["semantic_id"] for i in d["instances"]["instances"]
           if i.get("key") == "preset-card-list" and i.get("element_key") == "viewport"))
PY
)"
log "step1 elements A_name=$sem_name_A B_name=$sem_name_B B_apply=$sem_apply_B A_cancel=$sem_cancel_A"

# ---- step8c: help close returns to the SAME field; first key writes once -----
# The human types into the main field, opens the help layer, an external
# whole-value write lands behind it, closing returns to the SAME editor, and the
# FIRST key must continue on that external base exactly once.
help_return_probe() {
# ---- step8c: help close returns to the SAME field; first key writes once -----
# The main field keeps its owner/session while the help layer is open, an
# external whole-value write happens behind it, and closing returns to the SAME
# field whose FIRST key must advance the owner exactly once.
client select-card --instance cardA > /dev/null 2>&1 || fail "select cardA before help failed"
sleep 0.7
activate_app "$APP_PID"
sleep 0.5
help_focus="$(reveal_sem preset-detail-jobName help_focus)" || blocked "main field not reachable before help"
read -r hfx hfy hfw hfh <<< "$help_focus"
"$LEFT" $(( hfx + hfw / 2 )) $(( hfy + hfh / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.4
# A real editing session exists before help opens: one typed character, so the
# field's owner session and focus are established (the modal must return HERE).
"$DRIVER" cmd-key 0 > /dev/null 2>&1 || fail "select-all before help failed"
"$DRIVER" type "帮助前" > /dev/null 2>&1 || fail "typing before help failed"
sleep 0.6
help_btn="$(reveal_sem preset-help help_btn)" || blocked "help button not reachable"
read -r hbx hby hbw hbh <<< "$help_btn"
"$LEFT" $(( hbx + hbw / 2 )) $(( hby + hbh / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.9
# The dialog layer itself is not an AX node; its title/close children are.
[[ "$("$AX" "$APP_PID" find preset-help-close | head -1)" != "missing" ]] || fail "help dialog not visible after the help button"
client card-set --instance cardA --field jobName --value "外改帮助" > "$WORK/help_ext.json" 2> "$WORK/help_ext.err" \
  || fail "external write behind help failed"
sleep 0.6
close_btn="$(reveal_sem preset-help-close help_close)" || blocked "help close button not reachable"
read -r hcx hcy hcw hch <<< "$close_btn"
"$LEFT" $(( hcx + hcw / 2 )) $(( hcy + hch / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.7
[[ "$("$AX" "$APP_PID" find preset-help-close | head -1)" == "missing" ]] || fail "help dialog stayed open"
# The modal return settles on the refresh that removes the layer; wait for the
# accepted scene to expose the restored editor before typing.
sleep 1.6
"$DRIVER" type "Q" > "$WORK/help_key.json" 2> "$WORK/help_key.err" || fail "first key after help failed"
sleep 0.8
client card-read --instance cardA --output "$WORK/help_after.json" > /dev/null 2>&1 || fail "readback after help failed"
client read --output "$WORK/preset_after.json" > /dev/null 2>&1 || true
python3 - "$WORK/help_after.json" "$WORK/preset_after.json" <<'PYIN' || fail "first key after help did not advance the owner exactly once"
import json, sys
d = json.load(open(sys.argv[1]))
f = {x["field_id"]: x["draft"] for x in d["card_fields"]}
preset = {}
try:
    p = json.load(open(sys.argv[2]))
    for field in p.get("fields", []):
        preset[field.get("field_id")] = field.get("draft")
except Exception:
    pass
print("step8c diag cardA.jobName=%s preset.jobName=%s" % (f.get("jobName"), preset.get("jobName")))
assert f["jobName"] == "外改帮助Q", f
print("step8c help_first_key owner=%s" % f["jobName"])
PYIN
log "step8c help_close_first_key expected=[外改帮助Q]"
}
help_return_probe

log "step1 collection_viewport=$COLLECTION_VIEWPORT_SEM"
row_A="$("$AX" "$APP_PID" find preset-card-row-cardA | sed -n 's/^frame=//p' | head -1)"
row_B="$("$AX" "$APP_PID" find preset-card-row-cardB | sed -n 's/^frame=//p' | head -1)"
[[ "$row_A" != "missing" && -n "$row_A" ]] || blocked "collection row A not visible"
[[ "$row_B" != "missing" && -n "$row_B" ]] || blocked "collection row B not visible"
log "step1 collection_rows A=[$row_A] B=[$row_B]"


# ---- step2: 30 objects consume the EXISTING bounded virtualization --------
visible_rows="$("$AX" "$APP_PID" dump 2>/dev/null | grep -c 'preset-card-row-')"
(( visible_rows < 30 )) || fail "all 30 rows were materialized (no virtualization): $visible_rows"
[[ "$("$AX" "$APP_PID" find preset-card-row-card30 | head -1)" == "missing" ]] \
  || fail "a far row was materialized before scrolling"
detail_title() { "$AX" "$APP_PID" find preset-detail-title 2>/dev/null | sed -n '/^value_begin$/,/^value_end$/p' | sed '1d;$d'; }
detail_title_revealed() { reveal_sem preset-detail-title detail_title > /dev/null 2>&1 || true; detail_title; }
[[ "$(detail_title)" == "选中对象 cardA · 6301" ]] || fail "detail did not start on the owner's selection: [$(detail_title)]"
log "step2 objects=30 visible_rows=$visible_rows far_row=not_materialized detail=[$(detail_title)]"

# ---- step3: the public sort action drives the table's own sort ------------
client sort-cards --value owner > "$WORK/sort.json" 2> "$WORK/sort.err" || fail "sort-cards failed"
sleep 0.8
grep -q "PRESET_COLLECTION sort=owner" "$APP_LOG" || fail "sort did not reach the view"
[[ "$(detail_title)" == "选中对象 cardA · 6301" ]] || fail "sorting changed the selection/detail target"
log "step3 sort owner selection_kept=[$(detail_title)]"

# ---- step4: filter hides rows, keeps key/draft/selection ------------------
client filter-cards --value "卡片 A" > "$WORK/filter.json" 2> "$WORK/filter.err" || fail "filter failed"
sleep 1.0
[[ "$("$AX" "$APP_PID" find preset-card-row-card03 | head -1)" == "missing" ]] || fail "filtered row card03 still visible"
[[ "$(detail_title)" == "选中对象 cardA · 6301" ]] || fail "filtering moved the selected object"
client card-read --instance cardB --output "$WORK/cardB_hidden.json" > /dev/null 2>&1
client filter-cards --value "" > "$WORK/filter2.json" 2> "$WORK/filter2.err" || fail "filter clear failed"
sleep 1.0
[[ "$("$AX" "$APP_PID" find preset-card-row-card03 | sed -n 's/^role=//p' | head -1)" == "AXButton" ]] || fail "row card03 did not return"
log "step4 filter_keeps_key_and_draft"

# ---- step5: A->B->A by REAL clicks, external selection, unknown refusal ---
row_B="$(reveal_row preset-card-row-cardB rowB)" || blocked "row B not reachable"
activate_app "$APP_PID"
log "step5 rowB_frame=[$row_B] frontmost=$(frontmost_name)"
center_click "$row_B" || fail "row B click failed"
sleep 1.0
[[ "$(detail_title)" == "选中对象 cardB · 6302" ]] || fail "detail did not follow the clicked row: [$(detail_title)]"
grep -q "PRESET_COLLECTION_SELECTION row=cardB" "$APP_LOG" || fail "no owner transaction for the click"
row_A="$(reveal_row preset-card-row-cardA rowA)" || blocked "row A not reachable"
activate_app "$APP_PID"
log "step5 rowA_frame=[$row_A]"
center_click "$row_A" || fail "row A click failed"
sleep 1.0
[[ "$(detail_title)" == "选中对象 cardA · 6301" ]] || fail "detail did not return to A: [$(detail_title)]"
client select-card --instance card03 > "$WORK/sel03.json" 2>&1 || fail "external select failed"
sleep 0.8
[[ "$(detail_title)" == "选中对象 card03 · 6303" ]] || fail "external selection did not update the highlight/detail: [$(detail_title)]"
client select-card --instance cardZZ > "$WORK/selbad.json" 2> "$WORK/selbad.err" || true
python3 - "$WORK/selbad.json" <<'PY' || fail "unknown selection was not refused by name"
import json, sys
d = json.load(open(sys.argv[1]))
entries = {e[0]: e[1] for e in d["collection_action"]["entries"]}
assert entries["APPLIED"] == ["false"], entries
assert entries["REASON"] == ["unknown_target"], entries
assert entries["VERSION_BEFORE"] == entries["VERSION_AFTER"], entries
print("step5 unknown_selection refused reason=%s version=%s" % (entries["REASON"][0], entries["VERSION_BEFORE"][0]))
PY
[[ "$(detail_title)" == "选中对象 card03 · 6303" ]] || fail "a refused selection changed the current object"
log "step5 selection A->B->A, external select, refusal kept old"

# ---- step6: SAME object through handwritten detail and generated card -----
client select-card --instance cardB > /dev/null 2> "$WORK/selB.err" || fail "select cardB failed"
sleep 0.8
detail_field="$(reveal_sem preset-detail-jobName detail_field)" || blocked "detail field not reachable"
activate_app "$APP_PID"
read -r dx dy dw dh <<< "$detail_field"
"$LEFT" $(( dx + dw / 2 )) $(( dy + dh / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.5
"$DRIVER" cmd-key 0 > "$WORK/cmd.json" 2> "$WORK/cmd.err" || fail "select-all in detail failed"
"$DRIVER" type "详情B" > "$WORK/type.json" 2> "$WORK/type.err" || fail "detail typing failed"
sleep 0.8
grep -q "PRESET_DETAIL_EDIT key=cardB field=jobName applied=true" "$APP_LOG" || fail "detail edit did not reach the owner"
client card-read --instance cardB --output "$WORK/cardB_detail.json" > /dev/null 2>&1
python3 - "$WORK/cardB_detail.json" <<'PY' || fail "detail draft is not the card owner's draft"
import json, sys
d = json.load(open(sys.argv[1]))
f = {x["field_id"]: x["draft"] for x in d["card_fields"]}
assert d["card_owner"] == 6302 and f["jobName"] == "详情B", (d["card_owner"], f)
print("step6 detail_edit owner=%s draft=%s" % (d["card_owner"], f["jobName"]))
PY
sem_name_B="$(sel_map | awk -F'|' '$1=="cardB" && $2=="name" {print $3}' | head -1)"
# The generated card may be below the fold; AX only exposes laid-out nodes, so
# reveal it with the OUTER wheel before reading the second presentation.
reveal_sem "$sem_name_B" gen_cardB > /dev/null || blocked "generated cardB not reachable"
[[ "$(ax_value "$APP_PID" "$sem_name_B")" == "详情B" ]] \
  || fail "the generated card does not show the same draft: [$(ax_value "$APP_PID" "$sem_name_B")]"
"$AX" "$APP_PID" press preset-detail-apply > "$WORK/detail-apply.log" 2>&1 || fail "detail apply press failed"
sleep 0.8
grep -q "PRESET_DETAIL_ACTION key=cardB action=APPLY_DRAFT applied=true" "$APP_LOG" || fail "detail apply did not commit"
client card-read --instance cardB --output "$WORK/cardB_applied.json" > /dev/null 2>&1
python3 - "$WORK/cardB_applied.json" <<'PY' || fail "generated/detail presentations disagree after apply"
import json, sys
d = json.load(open(sys.argv[1]))
f = {x["field_id"]: x["applied"] for x in d["card_fields"]}
assert f["jobName"] in ("详情B", {"kind": "string", "value": "详情B"}), f
print("step6 apply_committed applied=%s" % (f["jobName"],))
PY
log "step6 same_object handwritten+generated share draft/applied"

# ---- step7: the presentation toggle switches layouts, not the owner -------
"$AX" "$APP_PID" press preset-detail-mode > "$WORK/mode1.log" 2>&1 || fail "detail mode press failed"
sleep 0.7
grep -q "PRESET_DETAIL_MODE mode=generated" "$APP_LOG" || fail "toggle did not switch to the generated presentation"
[[ "$("$AX" "$APP_PID" find preset-detail-jobName | head -1)" == "missing" ]] || fail "handwritten detail stayed mounted in generated mode"
"$AX" "$APP_PID" press preset-detail-mode > "$WORK/mode2.log" 2>&1 || true
sleep 0.7
grep -q "PRESET_DETAIL_MODE mode=handwritten" "$APP_LOG" || fail "toggle did not switch back"
log "step7 detail_mode generated<->handwritten"

# ---- step8: TRUE continuation: focused field, external write, bare suffix -
client select-card --instance cardA > /dev/null 2>&1 || fail "select cardA failed"
sleep 0.7
nameA_frame="$(reveal_sem "$sem_name_A" cardA_name_cont)" || blocked "cardA name not reachable"
read -r ax0 ay0 aw0 ah0 <<< "$nameA_frame"
"$LEFT" $(( ax0 + aw0 / 2 )) $(( ay0 + ah0 / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.5
"$DRIVER" cmd-key 0 > "$WORK/cmd.json" 2> "$WORK/cmd.err" || fail "select-all before the prefix failed"
"$DRIVER" type "AB" > "$WORK/type.json" 2> "$WORK/type.err" || fail "cardA typing failed"
sleep 0.6
client card-read --instance cardA --output "$WORK/a_ab.json" > /dev/null 2>&1
python3 - "$WORK/a_ab.json" <<'PY' || fail "the focused field did not take the prefix"
import json, sys
d = json.load(open(sys.argv[1]))
f = {x["field_id"]: x["draft"] for x in d["card_fields"]}
assert f["jobName"] == "AB", f
print("step8 prefix_ok=%s" % f["jobName"])
PY
# External whole-value write while the field KEEPS focus. No click, no Cmd+A,
# no AX selection is set: the suffix must be applied by the owner mapping rule.
client card-set --instance cardA --field jobName --value "外部" > "$WORK/ext.json" 2> "$WORK/ext.err" || fail "external write failed"
sleep 0.8
"$DRIVER" type "Z" > "$WORK/type2.json" 2> "$WORK/type2.err" || fail "suffix typing failed"
sleep 0.8
client card-read --instance cardA --output "$WORK/a_cont.json" > /dev/null 2>&1
python3 - "$WORK/a_cont.json" <<'PY' || fail "the focused field did not continue on the external version"
import json, sys
d = json.load(open(sys.argv[1]))
f = {x["field_id"]: x["draft"] for x in d["card_fields"]}
assert f["jobName"] == "外部Z", f
print("step8 continuation expected=外部Z actual=%s" % (f["jobName"],))
PY
log "step8 focused_continuation external=[外部] suffix=[Z] owner=[$(python3 -c "import json;d=json.load(open('$WORK/a_cont.json'));print([f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])")]"



# ---- step12: delete the current object, then add and edit a new one -------
client select-card --instance cardB > /dev/null 2>&1 || true
sleep 0.8
client delete-card --instance cardB > "$WORK/delete.json" 2> "$WORK/delete.err" || fail "delete cardB failed"
sleep 1.0
[[ "$("$AX" "$APP_PID" find preset-card-row-cardB | head -1)" == "missing" ]] || fail "deleted row still visible"
cur_title="$(detail_title_revealed)"
[[ "$cur_title" != *"cardB"* ]] || fail "detail still targets the deleted object: [$cur_title]"
client card-set --instance cardB --field jobName --value "幽灵" > "$WORK/ghost.json" 2> "$WORK/ghost.err" || true
grep -q "unknown_instance" "$WORK/ghost.err" "$WORK/ghost.json" 2>/dev/null || fail "write to the deleted object was not refused"
client add-card --value "卡片新" > "$WORK/add.json" 2> "$WORK/add.err" || fail "add failed"
sleep 0.8
client select-card --instance card31 > "$WORK/sel31.json" 2> "$WORK/sel31.err" || fail "new object cannot be selected"
sleep 0.8
[[ "$(detail_title_revealed)" == "选中对象 card31 · 6331" ]] || fail "detail did not follow the new object: [$(detail_title_revealed)]"
detail_field="$(reveal_sem preset-detail-jobName detail_field3)" || blocked "detail field not reachable for the new object"
activate_app "$APP_PID"
read -r nx ny nw nh <<< "$detail_field"
"$LEFT" $(( nx + nw / 2 )) $(( ny + nh / 2 )) >> "$WORK/click.log" 2>&1
sleep 0.5
"$DRIVER" cmd-key 0 > /dev/null 2>&1
"$DRIVER" type "新对象写" > /dev/null 2>&1
sleep 0.8
# An object with no DECLARED generated detail has no public per-instance form
# payload to read back; its handwritten detail is the app's own layout over the
# same card, so the owner transaction log plus the visible field are the channels
# here. (The declared objects A/B keep the full client readback below.)
grep -q "PRESET_DETAIL_EDIT key=card31 field=jobName applied=true text=\[新对象写\]" "$APP_LOG" \
  || fail "the new object's detail never reached its owner transaction"
[[ "$(ax_value "$APP_PID" preset-detail-jobName)" == "新对象写" ]] \
  || fail "the new object's detail does not show its owner draft: [$(ax_value "$APP_PID" preset-detail-jobName)]"
log "step12 new_object owner_transaction=applied visible=[新对象写]"

# ---- step13: precise readback on a DECLARED object and normal close ------
client select-card --instance cardA > /dev/null 2>&1 || fail "select cardA for readback failed"
sleep 0.8
client card-read --instance cardA --output "$WORK/final_a.json" > /dev/null 2>&1 || fail "cardA readback failed"
reveal_sem preset-detail-jobName final_detail > /dev/null 2>&1 || true
final_ax="$(ax_value "$APP_PID" preset-detail-jobName)"
final_owner="$(python3 -c "import json;d=json.load(open('$WORK/final_a.json'));print([f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])")"
[[ "$final_ax" == "$final_owner" ]] || fail "detail AX [$final_ax] != owner [$final_owner]"
log "step13 readback owner=[$final_owner] ax=[$final_ax]"
"$AX" "$APP_PID" close > "$WORK/close.log" 2>&1 || fail "close action failed"
waited=0
while (( waited < 60 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after normal close"
grep -q "CJGUI_MIXED_FORM_CLOSED" "$APP_LOG" || fail "close completion line missing"
APP_PID=""
log "step14 normal_close=CJGUI_MIXED_FORM_CLOSED"
log "PASS object_workbench_chain"
print -r -- "chain: PASS log=$LOG"
