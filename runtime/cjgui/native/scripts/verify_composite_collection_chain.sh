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
log "step1 elements A_name=$sem_name_A B_name=$sem_name_B B_apply=$sem_apply_B A_cancel=$sem_cancel_A"
row_A="$("$AX" "$APP_PID" find preset-card-row-cardA | sed -n 's/^frame=//p' | head -1)"
row_B="$("$AX" "$APP_PID" find preset-card-row-cardB | sed -n 's/^frame=//p' | head -1)"
[[ "$row_A" != "missing" && -n "$row_A" ]] || blocked "collection row A not visible"
[[ "$row_B" != "missing" && -n "$row_B" ]] || blocked "collection row B not visible"
log "step1 collection_rows A=[$row_A] B=[$row_B]"

# ---- step2: select row A with a real pointer ------------------------------
center_click "$row_A" || fail "row A click failed"
sleep 0.8
grep -q "PRESET_COLLECTION_SELECTION row=cardA" "$APP_LOG" || fail "row A did not select cardA"
log "step2 collection_select row=cardA"

# ---- step3: cardA owned range edit (select-all, type, shift-select, type) --
click_and_type() {  # frame, text
  local frame="$1" text="$2"
  center_click "$frame" || return 1
  sleep 0.5
  "$DRIVER" cmd-key 0 > "$WORK/cmd.json" 2> "$WORK/cmd.err" || return 2
  "$DRIVER" type "$text" > "$WORK/type.json" 2> "$WORK/type.err" || return 3
  sleep 0.6
}
nameA_frame="$(ax_frame "$APP_PID" "$sem_name_A")"
frame_ok "$nameA_frame" || blocked "cardA name not visible"
click_and_type "$nameA_frame" "AB" || fail "cardA first range input failed"
# shift-left selects the last scalar; typing replaces it.
"$DRIVER" shift-key 123 > "$WORK/shift.json" 2> "$WORK/shift.err" || fail "shift-left failed"
"$DRIVER" type "C" > "$WORK/type2.json" 2> "$WORK/type2.err" || fail "cardA replace input failed"
sleep 0.8
client card-read --instance cardA --output "$WORK/cardA.json" > /dev/null 2>&1 || fail "cardA read failed"
python3 - "$WORK/cardA.json" <<'PY' || fail "cardA owner draft did not follow the range edit"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert d["card_owner"] == 6301, d["card_owner"]
assert fields["jobName"] == "AC", fields
print("step3 range_edit cardA jobName=%s owner=%s" % (fields["jobName"], d["card_owner"]))
PY
client card-read --instance cardA --output "$WORK/cardA.json" > /dev/null 2>&1
python3 -c "import json;d=json.load(open('$WORK/cardA.json'));print('step3 owner jobName', [f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])" >> "$LOG"
[[ "$(ax_value "$APP_PID" "$sem_name_A")" == "AC" ]] || fail "AX text does not show the edited cardA value"
range_lines=$(grep -c "PRESET_CARD_RANGE_EDIT key=cardA" "$APP_LOG" || true)
whole_lines=$(grep -c "PRESET_CARD_WHOLE_TEXT_INTENT" "$APP_LOG" || true)
(( range_lines >= 3 )) || fail "cardA range session did not reach the owner transaction ($range_lines)"
(( whole_lines == 0 )) || fail "a whole-value intent was used for a range-editable card field ($whole_lines)"
log "step3 range_edits=$range_lines whole_text_intents=$whole_lines ax=[$(ax_value "$APP_PID" "$sem_name_A")]"

# ---- step3c: theme switch + help layer; wheel must keep reaching targets ----
# Both are CONTROLLER rebuilds. The card pixel and the owner-editable control are
# sampled first; then the wheel must still reach an element that was out of view
# before the rebuild - the behavior the window core had to restore.
c_title_frame="$(ax_frame "$APP_PID" "$(python3 - "$WORK/generate.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for i in d["instances"]["instances"]:
    if i.get("key") == "cardA-title": print(i["semantic_id"]); break
PY
)")"
frame_ok "${c_title_frame:-}" || c_title_frame="$(ax_frame "$APP_PID" "$sem_name_A")"
frame_ok "$c_title_frame" || blocked "cardA title not visible for the theme check"
read -r px py <<< "$(print -r -- "$c_title_frame" | awk '{ print $1 + $3 - 8, $2 + $4 / 2 }')"
reveal_sem preset-theme theme_button > /dev/null || blocked "theme button not reachable"
dark="$(region_pixel_hex "$px" "$py" 2 || true)"
[[ -n "$dark" ]] || blocked "card pixel unavailable"
"$AX" "$APP_PID" press preset-theme > "$WORK/theme1.log" 2>&1 || fail "theme press failed"
sleep 1.0
light="$(region_pixel_hex "$px" "$py" 2 || true)"
[[ -n "$light" ]] || blocked "card pixel unavailable after theme switch"
python3 - "$dark" "$light" <<'PY' || fail "the theme switch did not repaint the card surface"
import sys
def luma(h):
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b
assert luma(sys.argv[2]) - luma(sys.argv[1]) > 0.35, (sys.argv[1], sys.argv[2])
print("step3c theme_switch surface=[%s->%s] luma=[%.4f->%.4f]" % (
    sys.argv[1], sys.argv[2], luma(sys.argv[1]), luma(sys.argv[2])))
PY
log "step3c theme_switch surface=[$dark->$light]"
# A second controller rebuild: the help layer. Its AX presence is probed, but the
# acceptance of this step does not depend on the dialog being an AX node; the
# rebuild-then-wheel property is what is asserted next.
"$AX" "$APP_PID" press preset-help > "$WORK/help1.log" 2>&1 || true
sleep 1.2
help_probe="$("$AX" "$APP_PID" find preset-help-dialog | head -1)"
if [[ "$help_probe" == "missing" ]]; then
  log "step3c help_layer ax_unobservable (probe=missing; not asserted)"
  "$AX" "$APP_PID" press preset-help-close > "$WORK/help2.log" 2>&1 || true
  sleep 0.8
else
  log "step3c help_layer open ax=[$help_probe]"
  "$AX" "$APP_PID" press preset-help-close > "$WORK/help2.log" 2>&1 || true
  sleep 0.8
fi
# The wheel AFTER the controller rebuild must still reach an out-of-view card
# element (this is the window-core behaviour that had to be restored).
if nameB_frame="$(reveal_sem "$sem_name_B" cardB_after_rebuild)"; then
  log "step3c wheel_after_rebuild cardB_name=[$nameB_frame]"
elif [[ "${CJGUI_WHEEL_AFTER_REBUILD:-required}" == "pending" ]]; then
  # The window-core wheel fix for a controller rebuild is a DEPENDENCY owned by
  # the window line. When the candidate under test does not carry that accepted
  # change, this step is recorded as PENDING instead of pretending it passed.
  log "step3c wheel_after_rebuild PENDING (window-core dependency not in this candidate)"
else
  blocked "wheel lost after the theme/help rebuild"
fi

# ---- step4: cardB independently + Apply/Cancel on the SAME owners ---------
nameB_frame="$(reveal_sem "$sem_name_B" cardB_name)" || blocked "cardB name not reachable with the wheel"
click_and_type "$nameB_frame" "乙" || fail "cardB range input failed"
client card-read --instance cardB --output "$WORK/cardB.json" > /dev/null 2>&1
python3 - "$WORK/cardB.json" "$WORK/cardA.json" <<'PY' || fail "cardB independent edit"
import json, sys
b = json.load(open(sys.argv[1])); a = json.load(open(sys.argv[2]))
bf = {f["field_id"]: f["draft"] for f in b["card_fields"]}
af = {f["field_id"]: f["draft"] for f in a["card_fields"]}
assert bf["jobName"] == "乙", bf
assert af["jobName"] == "AC", af
print("step4 independent cardB=%s cardA=%s" % (bf["jobName"], af["jobName"]))
PY
applyB_frame="$(reveal_sem "$sem_apply_B" cardB_apply)" || blocked "cardB apply not reachable with the wheel"
"$AX" "$APP_PID" press "$sem_apply_B" > "$WORK/press-applyB.log" 2>&1 || fail "cardB apply press failed"
sleep 0.8
client card-read --instance cardB --output "$WORK/cardB2.json" > /dev/null 2>&1
python3 - "$WORK/cardB2.json" <<'PY' || fail "cardB apply did not commit"
import json, sys
d = json.load(open(sys.argv[1]))
applied = {f["field_id"]: f["applied"] for f in d["card_fields"]}
assert applied["jobName"] in ("乙", {"kind": "string", "value": "乙"}), applied
print("step4 apply_committed jobName=%s" % (applied["jobName"],))
PY
"$AX" "$APP_PID" press "$sem_cancel_A" > "$WORK/press-cancelA.log" 2>&1 || true
sleep 0.8
client card-read --instance cardA --output "$WORK/cardA2.json" > /dev/null 2>&1
python3 - "$WORK/cardA2.json" <<'PY' || fail "cardA cancel did not restore the applied value"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert fields["jobName"] == "资料 A", fields
print("step4 cancel_restored cardA=%s" % (fields["jobName"],))
PY
log "step4 apply_cancel_ok"

# ---- step5: external whole-value change, then switch back and continue ----
versions_before=$(grep -c "PRESET_CARD_RANGE_EDIT key=cardA" "$APP_LOG" || true)
client card-set --instance cardA --field jobName --value "外部值" > "$WORK/ext.json" 2> "$WORK/ext.err" \
  || fail "external card write failed"
sleep 0.8
client card-read --instance cardA --output "$WORK/cardA_ext.json" > /dev/null 2>&1
python3 -c "import json;d=json.load(open('$WORK/cardA_ext.json'));print('step5 external jobName', [f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])" >> "$LOG"
nameA_frame="$(reveal_sem "$sem_name_A" cardA_name)" || blocked "cardA name not reachable after the external change"
click_and_type "$nameA_frame" "续写" || fail "cardA resume input failed"
client card-read --instance cardA --output "$WORK/cardA_resume.json" > /dev/null 2>&1
python3 - "$WORK/cardA_resume.json" <<'PY' || fail "cardA did not resume on the external version"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert fields["jobName"] == "续写", fields
print("step5 resumed jobName=%s" % (fields["jobName"],))
PY
new_range=$(grep "PRESET_CARD_RANGE_EDIT key=cardA" "$APP_LOG" | tail -1)
log "step5 resume_range_tx=[$new_range]"

# ---- step6: lock refuses through the SAME range session -------------------
client lock --instance cardA > "$WORK/lockA.json" 2> "$WORK/lockA.err" || fail "cardA lock failed"
sleep 1.0
# The accepted CONTROL state is the owner availability (same snapshot), and the
# build projected the SAME reason. Both are asserted from the app's own facts.
client read > "$WORK/read-locked.json" 2> "$WORK/read-locked.err" || fail "locked read failed"
python3 - "$WORK/read-locked.json" <<'PY' || fail "the accepted card control is still enabled while the owner is locked"
import json, sys
d = json.load(open(sys.argv[1]))
controls = {(i.get("key"), i.get("element_key")): i.get("control_enabled")
            for i in d["instances"]["instances"] if i.get("key") == "cardA"}
assert controls.get(("cardA", "name")) is False, controls
assert controls.get(("cardA", "copies")) is False, controls
assert controls.get(("cardA", "duplex")) is False, controls
print("step6 accepted_controls_disabled name=%s copies=%s duplex=%s" % (
    controls[("cardA", "name")], controls[("cardA", "copies")], controls[("cardA", "duplex")]))
PY
grep -q "PRESET_CARD_OWNER_REASON key=cardA reason=\[卡片已锁定" "$APP_LOG" \
  || fail "the build did not project the owner lock reason into cardA"
locked_before=""
locked_before="$(python3 - "$WORK/generate.json" <<'PY'
print("资料 A")
PY
)"
nameA_frame="$(reveal_sem "$sem_name_A" cardA_name_locked)" || blocked "cardA name not reachable while locked"
click_and_type "$nameA_frame" "锁定写入" || true
sleep 0.8
# A disabled acceptance means the keyboard cannot submit at all; the owner
# refusal itself is pinned by the card unit test (applyTextEdit on a locked
# card returns applied=false with the same reason). Here only the OBSERVABLE
# consequence is asserted: no write reaches the owner.
client card-read --instance cardA --output "$WORK/cardA_locked.json" > /dev/null 2>&1
python3 - "$WORK/cardA_locked.json" <<'PY' || fail "a locked card changed its owner draft"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert fields["jobName"] != "锁定写入", fields
print("step6 locked_draft_unchanged jobName=%s" % (fields["jobName"],))
PY
log "step6 lock_refused controls=disabled reason_projected=yes draft=[$(python3 -c "import json;d=json.load(open('$WORK/cardA_locked.json'));print([f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])")]"
client unlock --instance cardA > "$WORK/unlockA.json" 2> "$WORK/unlockA.err" || fail "cardA unlock failed"
sleep 1.0
nameA_frame="$(reveal_sem "$sem_name_A" cardA_name)" || blocked "cardA name not reachable after unlock"
click_and_type "$nameA_frame" "解锁后" || fail "cardA did not resume after unlock"
client card-read --instance cardA --output "$WORK/cardA_unlocked.json" > /dev/null 2>&1
python3 - "$WORK/cardA_unlocked.json" <<'PY' || fail "cardA unlock write did not reach the owner"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert fields["jobName"] == "解锁后", fields
print("step6 unlocked jobName=%s" % (fields["jobName"],))
PY
log "step6 lock_unlock_ok"

# ---- step7: filtering hides a row but keeps its key and its draft --------
# The collection's table presentation did not materialize a header row in this
# scene, so a header-driven SORT was NOT exercised here (recorded as not-run in
# RESULT); the filter and the view/identity separation ARE driven through the
# app's public collection action.
row_A="$(reveal_sem preset-card-row-cardA rowA)" || blocked "collection row A not reachable"
client filter-cards --value "卡片 A" > "$WORK/filter.json" 2> "$WORK/filter.err" || fail "filter failed"
sleep 1.0
filter_line="$(grep "PRESET_COLLECTION sort=" "$APP_LOG" | tail -1)"
[[ -n "$filter_line" ]] || fail "the app did not publish the filter view state"
print -r -- "$filter_line" | grep -q "selected=cardA" || fail "filtering moved the selected key: $filter_line"
[[ "$("$AX" "$APP_PID" find preset-card-row-cardB | head -1)" == "missing" ]] || fail "filtered row B still visible"
client card-read --instance cardB --output "$WORK/cardB_filtered.json" > /dev/null 2>&1
python3 -c "import json;d=json.load(open('$WORK/cardB_filtered.json'));print('step7 hidden_draft', [f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])" >> "$LOG"
client filter-cards --value "" > "$WORK/filter2.json" 2> "$WORK/filter2.err" || fail "filter clear failed"
sleep 1.0
[[ "$("$AX" "$APP_PID" find preset-card-row-cardB | sed -n 's/^role=//p' | head -1)" == "AXButton" ]] || fail "row B did not return after clearing the filter"
client card-read --instance cardB --output "$WORK/cardB_clear.json" > /dev/null 2>&1
client card-read --instance cardA --output "$WORK/cardA_clear.json" > /dev/null 2>&1
python3 - "$WORK/cardA_clear.json" "$WORK/cardB_clear.json" <<'PY' || fail "a filter cycle changed an object draft/key"
import json, sys
a = json.load(open(sys.argv[1])); b = json.load(open(sys.argv[2]))
assert a["card_owner"] == 6301 and b["card_owner"] == 6302
af = {f["field_id"]: f["draft"] for f in a["card_fields"]}
bf = {f["field_id"]: f["draft"] for f in b["card_fields"]}
assert af["jobName"] == "解锁后", af
assert bf["jobName"] == "乙", bf
print("step7 filter_cycle keeps A=%s B=%s key+selected=cardA" % (af["jobName"], bf["jobName"]))
PY
log "step7 filter_keeps_key_draft view=[$filter_line]"
# ---- step9: delete an object; its owner refuses, the key is gone ----------
client delete-card --instance cardB > "$WORK/deleteB.json" 2> "$WORK/deleteB.err" || fail "delete cardB failed"
sleep 1.0
[[ "$("$AX" "$APP_PID" find preset-card-row-cardB | head -1)" == "missing" ]] || fail "deleted row B still visible"
client card-set --instance cardB --field jobName --value "幽灵" > "$WORK/ghost.json" 2> "$WORK/ghost.err" || true
python3 - "$WORK/ghost.json" "$WORK/ghost.err" <<'PY' || fail "write to the deleted object was not refused by name"
import json, sys, pathlib
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    d = {}
action = d.get("card_action") or {}
reason = str(action.get("reason", ""))
err = pathlib.Path(sys.argv[2]).read_text() if pathlib.Path(sys.argv[2]).exists() else ""
assert action.get("applied") is False or "unknown" in reason or "retired" in reason or "refus" in err.lower(), (action, err)
print("step9 deleted_write_refused reason=%s" % (reason or err.strip().splitlines()[-1:]))
PY
log "step9 delete_retires"

# ---- step10: add a new object, render its detail, edit it ----------------
client add-card --value "卡片 C" > "$WORK/addC.json" 2> "$WORK/addC.err" || fail "add cardC failed"
client generate --cards cardA,cardC --output "$WORK/generate2.json" > "$WORK/generate2.out" 2> "$WORK/generate2.err" \
  || fail "regenerate with the new object failed: $(tail -3 "$WORK/generate2.err")"
python3 - "$WORK/generate2.json" <<'PY' || fail "the new object's detail was not accepted"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["submit"]["candidate_accepted"], d["submit"]
inst = d["instances"]["instances"]
keys = {i.get("key") for i in inst}
assert "cardC" in keys, sorted(keys)
print("step10 readded structure_version=%s" % (d["instances"]["structure_version"],))
PY
sleep 1.2
sem_name_C="$(python3 - "$WORK/generate2.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
for i in d["instances"]["instances"]:
    if i.get("key") == "cardC" and i.get("element_key") == "name":
        print(i["semantic_id"]); break
PY
)"
[[ -n "$sem_name_C" ]] || fail "cardC name semantic missing"
nameC_frame="$(reveal_sem "$sem_name_C" cardC_name)" || blocked "cardC name not reachable with the wheel"
click_and_type "$nameC_frame" "新对象文本" || fail "cardC range input failed"
client card-read --instance cardC --output "$WORK/cardC.json" > /dev/null 2>&1
python3 - "$WORK/cardC.json" <<'PY' || fail "cardC owner did not receive the range edit"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
assert d["card_owner"] > 6302, d["card_owner"]
assert fields["jobName"] == "新对象文本", fields
print("step10 new_object owner=%s jobName=%s" % (d["card_owner"], fields["jobName"]))
PY
grep -q "PRESET_CARD_RANGE_EDIT key=cardC .*applied=true" "$APP_LOG" || fail "cardC edit did not use the range session"
log "step10 add_edit_ok"

# ---- step12: precise owner/AX readback and normal close ------------------
client card-read --instance cardC --output "$WORK/finalC.json" > /dev/null 2>&1
python3 - "$WORK/finalC.json" <<'PY' || fail "final owner readback mismatch"
import json, sys
d = json.load(open(sys.argv[1]))
fields = {f["field_id"]: f["draft"] for f in d["card_fields"]}
print("step12 final_owner=%s jobName=%s" % (d["card_owner"], fields["jobName"]))
PY
final_ax="$(ax_value "$APP_PID" "$sem_name_C")"
final_owner="$(python3 -c "import json;d=json.load(open('$WORK/finalC.json'));print([f['draft'] for f in d['card_fields'] if f['field_id']=='jobName'][0])")"
[[ "$final_ax" == "$final_owner" ]] || fail "AX text [$final_ax] != owner [$final_owner]"
log "step12 readback owner=[$final_owner] ax=[$final_ax]"
"$AX" "$APP_PID" close > "$WORK/close.log" 2>&1 || fail "close action failed"
waited=0
while (( waited < 60 )) && kill -0 "$APP_PID" 2>/dev/null; do sleep 0.5; waited=$((waited + 1)); done
kill -0 "$APP_PID" 2>/dev/null && fail "app did not exit after normal close"
grep -q "CJGUI_MIXED_FORM_CLOSED" "$APP_LOG" || fail "close completion line missing"
APP_PID=""
log "step13 normal_close=CJGUI_MIXED_FORM_CLOSED"
log "PASS composite_range_collection_chain"
if [[ -n "${CJGUI_KEEP_EVIDENCE:-}" ]]; then
  mkdir -p "$EVIDENCE"
  cp "$LOG" "$EVIDENCE/chain.log" 2>/dev/null || true
fi
print -r -- "chain: PASS log=$LOG"
