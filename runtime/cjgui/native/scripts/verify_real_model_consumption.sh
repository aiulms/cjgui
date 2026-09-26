#!/usr/bin/env zsh
# Real-model consumption of the PUBLIC generated-UI surface.
#
# The point of this script is NOT to prove a model is good at UI: it is to show
# that a model session which ONLY receives public information - the business
# goal, the capability description the running application publishes, the public
# client usage and the temporary instance's public interface - can drive the same
# discovery -> generate -> submit -> scene-accept -> edit -> read-back chain that
# a human author drives, with no author/consumer source, no private test request
# and no pre-written full candidate.
#
# Two modes, run in this order by the orchestrator:
#
#   discover --out DIR [--export-root R]
#       Exports a preview (or reuses R), launches the two exported generated-UI
#       consumers with their own identities, records what the PUBLIC client
#       answers (capabilities, structure, fields), writes the public-interface
#       text handed to the model, then reclaims everything it started.
#
#   apply --payloads DIR --out DIR [--export-root R]
#       Launches fresh instances and runs the model's own payloads:
#         rule domain:
#           payload rule-generate.txt  -> submit at version 0 -> scene accepted
#           the model's own editor     -> real desktop input -> exact read-back
#           payload rule-generate.txt  -> RE-SUBMITTED AT A STALE VERSION is
#             refused by the public structure_version_conflict, the old interface
#             keeps answering, then payload rule-rearrange.txt is submitted at
#             the version the public read-back reports -> scene accepted
#           the model's own action     -> real desktop press -> owner applied
#             read-back, then one more real edit into a model-declared editor
#             whose legal value comes from that field's published type/range
#             (desktop continuation after the apply), and finally the exact
#             read-back is fed BACK to the model for one dependent confirmation
#         second domain (same public client, no rule-specific script):
#           payload panel-generate.txt -> submit -> scene accepted -> public
#           field operation -> exact read-back
#
# Payload files are the model's raw output, recorded beside this log with their
# sha256. `--payloads DIR` must also contain `model-meta.txt`, the recorded model
# identity / call count / input-output sizes for the report; it is evidence, not
# an input to any check.
#
# Exit codes: 0 verified; 3 headless verification passed but a real desktop-input
# segment was blocked (the exact condition is logged); 1 a verified claim failed.
#
# What this does NOT claim: human physical input, a GPU presentation check, or
# that the model produced a good-looking UI. Desktop input is synthetic
# CGEvent/AX tool input and is labelled as such in every evidence line.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPOSITORY_ROOT="$(cd "$RUNTIME_DIR/../.." && pwd)"

MODE="${1:-}"
shift || true
OUT_DIR=""
PAYLOADS_DIR=""
export_root=""
while (( $# > 0 )); do
  case "$1" in
    --out) OUT_DIR="$2"; shift 2 ;;
    --payloads) PAYLOADS_DIR="$2"; shift 2 ;;
    --export-root) export_root="$2"; shift 2 ;;
    *) print -u2 -- "unknown argument: $1"; exit 2 ;;
  esac
done
[[ "$MODE" == "discover" || "$MODE" == "apply" ]] || {
  print -u2 -- "usage: verify_real_model_consumption.sh discover|apply --out DIR [--payloads DIR] [--export-root R]"
  exit 2
}
[[ -n "$OUT_DIR" ]] || { print -u2 -- "--out is required"; exit 2; }
mkdir -p "$OUT_DIR"
WORK="$OUT_DIR/work"
mkdir -p "$WORK"
LOG="$OUT_DIR/real-model.log"
: > "$LOG"
log() { print -r -- "$*" >> "$LOG"; }
say() { print -r -- "$*" | tee -a "$LOG"; }
fail() { log "FAIL $*"; print -u2 -- "FAIL $*"; tail -40 "$LOG" >&2 || true; exit 1; }
BLOCKED_DESKTOP=""
blocked() { BLOCKED_DESKTOP="$1"; log "BLOCKED $1 reason=$2"; }
finish() {
  if [[ -n "$BLOCKED_DESKTOP" ]]; then
    say "BLOCKED desktop segment=$BLOCKED_DESKTOP (headless model-consumption evidence is complete)"
    exit 3
  fi
  say "PASSED real-model consumption (mode=$MODE)"
  exit 0
}

source "$SCRIPT_DIR/lib_cjgui_instance.sh"
CLIENT=""  # resolved from the export root below
source "$SCRIPT_DIR/lib_cjgui_desktop_input.sh"

set +u
source "${CJGUI_CANGJIE_HOME:-/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}/envsetup.sh"
set -u
export SDKROOT="$(xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"

typeset -a ROUND_PIDS ROUND_DIRS ROUND_EXECS ROUND_DESCS
typeset -a CANDIDATE_EXECS CANDIDATE_DIRS CANDIDATE_DESCS
register_candidate() { CANDIDATE_EXECS+=("$1"); CANDIDATE_DIRS+=("$2"); CANDIDATE_DESCS+=("${3:-}"); }
cleanup() {
  if (( ${#ROUND_PIDS} > 0 )); then
    local index=1
    while (( index <= ${#ROUND_PIDS} )); do
      cjgui_terminate_owned "${ROUND_PIDS[index]}" "${ROUND_DESCS[index]}" "${ROUND_EXECS[index]}" \
        "${ROUND_DIRS[index]}" || true
      index=$(( index + 1 ))
    done
  fi
  cjgui_reclaim_candidates log
}
trap cleanup EXIT

# --- 0. the export this round consumes -------------------------------------
if [[ -n "$export_root" && -d "$export_root/framework/cjgui/src" ]]; then
  log "step0 export_reused=true root='$export_root'"
else
  export_root="$OUT_DIR/export"
  [[ -e "$export_root" ]] && fail "export destination already exists: $export_root"
  zsh "$RUNTIME_DIR/scripts/export_framework_preview.sh" "$export_root" >> "$LOG" 2>&1 || fail "export failed"
  log "step0 export_ok root='$export_root'"
fi
CLIENT="$export_root/framework/cjgui/shared_operation_core/client.py"
[[ -f "$CLIENT" ]] || fail "exported client missing at $CLIENT"
export_fingerprint="$(python3 "$RUNTIME_DIR/native/scripts/export_fingerprint.py" \
  "$export_root" "$RUNTIME_DIR" "$REPOSITORY_ROOT" | head -1)" || fail "export fingerprint check failed"
log "step0b export_fingerprint $export_fingerprint"

# --- 1. launch the two exported consumers with their own identities ---------
RUN_TAG="$(date +%Y%m%d%H%M%S)-$$"
ROUND_STARTED="$(date +%s)"
build_failure_hint() { grep -qE 'error:|error\[' "$1" 2>/dev/null; }
prepare_consumer() { # prepare_consumer <name> <name-token> <bundle-token> <suffix>
  local name="$1" token="$2" bundle="$3" suffix="$4"
  local src="$export_root/consumers/$name" dir="$WORK/$name-round"
  [[ -d "$src" ]] || fail "exported consumer $name missing"
  cjgui_prepare_app_copy "$src" "$dir" "$export_root/framework/cjgui" "$token" "$suffix" "$bundle" \
    || fail "per-round copy of $name failed"
  print -r -- "$dir"
}
register_round() { ROUND_PIDS+=("$1"); ROUND_DESCS+=("$2"); ROUND_EXECS+=("$3"); ROUND_DIRS+=("$4"); }

launch_rule() {
  RULE_DIR="$(prepare_consumer rule_set_window_app "CJGUIRuleSet" \
    "org.cangjie.cjgui.rule-set.example" "Model${RUN_TAG}")"
  RULE_EXEC="$RULE_DIR/target/release/CJGUIRuleSetModel${RUN_TAG}.app/Contents/MacOS/CJGUIRuleSetModel${RUN_TAG}"
  RULE_STDOUT="$WORK/rule-window.log"
  register_candidate "$RULE_EXEC" "$RULE_DIR"
  ( cd "$RULE_DIR" && nohup zsh run.sh > "$RULE_STDOUT" 2>&1 & )
  RULE_DESCRIPTOR=""
  local waited=0
  while (( waited < 240 )); do
    RULE_DESCRIPTOR="$(grep 'CJGUI_RULE_SET_READY DESCRIPTOR_PATH' "$RULE_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    [[ -n "$RULE_DESCRIPTOR" && -f "$RULE_DESCRIPTOR" ]] && break
    sleep 2
    waited=$(( waited + 2 ))
  done
  [[ -f "${RULE_DESCRIPTOR:-}" ]] || {
    build_failure_hint "$RULE_STDOUT" && { tail -8 "$RULE_STDOUT" >> "$LOG" || true; fail "exported rule window did not build"; }
    fail "exported rule window did not publish a descriptor"
  }
  RULE_PID="$(cjgui_descriptor_owner_pid "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" "$ROUND_STARTED" || true)"
  if [[ -z "$RULE_PID" ]]; then
    ps -eo pid,command | grep -F "$RULE_DIR" | grep -v grep >> "$LOG" 2>/dev/null || true
    fail "rule descriptor has no matching owner (exec=$RULE_EXEC)"
  fi
  cjgui_pid_owns "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR" || fail "rule pid is not this round's instance"
  register_round "$RULE_PID" "$RULE_DESCRIPTOR" "$RULE_EXEC" "$RULE_DIR"
  log "step1 rule_instance pid=$RULE_PID descriptor=$RULE_DESCRIPTOR origin=export"
}

launch_panel() {
  PANEL_DIR="$(prepare_consumer generated_panel_consumer "CJGUICollaborationStarter" \
    "org.example.cjgui.collaboration-starter" "Model${RUN_TAG}")"
  PANEL_EXEC="$PANEL_DIR/target/release/CJGUICollaborationStarterModel${RUN_TAG}.app/Contents/MacOS/CJGUICollaborationStarterModel${RUN_TAG}"
  PANEL_STDOUT="$WORK/panel.log"
  register_candidate "$PANEL_EXEC" "$PANEL_DIR"
  ( cd "$PANEL_DIR" && nohup zsh run.sh > "$PANEL_STDOUT" 2>&1 & )
  PANEL_DESCRIPTOR=""
  local waited=0
  while (( waited < 240 )); do
    PANEL_DESCRIPTOR="$(grep 'CJGUI_COLLABORATION_READY DESCRIPTOR_PATH' "$PANEL_STDOUT" 2>/dev/null | tail -1 | awk '{print $NF}' || true)"
    [[ -n "$PANEL_DESCRIPTOR" && -f "$PANEL_DESCRIPTOR" ]] && break
    sleep 2
    waited=$(( waited + 2 ))
  done
  [[ -f "${PANEL_DESCRIPTOR:-}" ]] || {
    build_failure_hint "$PANEL_STDOUT" && { tail -8 "$PANEL_STDOUT" >> "$LOG" || true; fail "exported panel consumer did not build"; }
    fail "exported panel consumer did not publish a descriptor"
  }
  PANEL_PID="$(cjgui_descriptor_owner_pid "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" "$ROUND_STARTED" || true)"
  if [[ -z "$PANEL_PID" ]]; then
    ps -eo pid,command | grep -F "$PANEL_DIR" | grep -v grep >> "$LOG" 2>/dev/null || true
    fail "panel descriptor has no matching owner (exec=$PANEL_EXEC)"
  fi
  cjgui_pid_owns "$PANEL_PID" "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR" || fail "panel pid is not this round's instance"
  register_round "$PANEL_PID" "$PANEL_DESCRIPTOR" "$PANEL_EXEC" "$PANEL_DIR"
  log "step1 panel_instance pid=$PANEL_PID descriptor=$PANEL_DESCRIPTOR origin=export"
}

assert_export_origins() { # assert_export_origins <stdout-log> <name>
  local log_file="$1" name="$2"
  [[ -f "$log_file" ]] || fail "$name has no stdout log"
  grep -qF "source_origin runtime=$export_root/framework/cjgui" "$log_file" \
    || fail "$name did not resolve its runtime inside the export root"
  grep -qF "resource_origin=$export_root/framework/cjgui/resources/" "$log_file" \
    || fail "$name did not resolve its resources inside the export root"
  if [[ "$export_root" != "$RUNTIME_DIR"* ]] && grep -E 'source_origin|resource_origin' "$log_file" | grep -qF "$RUNTIME_DIR"; then
    fail "$name resolved an origin from the author tree"
  fi
  log "origin_ok process=$name export_root='$export_root'"
}

write_public_interface() {
  cat > "$OUT_DIR/public-interface.txt" <<PUBLIC
PUBLIC CLIENT USAGE (the only interface a consumer needs)

client: framework/cjgui/shared_operation_core/client.py
invocation: python3 <client.py> <DESCRIPTOR_PATH> <command> [options]

  generated-capabilities                 publish the application's declared kinds,
                                         properties, actions (with argument names)
                                         and fields (label, writer, argument,
                                         constraints, generated input kind)
  generated-structure                    current accepted structure + version
  generated-fields                       current accepted field values/versions
  generated-instances                    the accepted generated instances, each
                                         addressed by its DECLARED key: accepted
                                         component identity, composite element,
                                         field/action references and the geometry
                                         the window really accepted
  generated-snapshot                     ONE atomic read: stream/cursor identity,
                                         the separated owner and scene facts, and
                                         the field/structure/instance sections of
                                         the same call
  generated-candidate <token>            the terminal state of ONE submission
                                         attempt (its own token/receipt)
  generated-submit --structure-version V --payload-file F
                                         submit a candidate structure
  invoke <version> <ACTION> --target <resourceId> [--arg name=TYPE:value]
                                         call a declared action
  get                                    read the selected record's resources

Candidate structure text (line protocol, one line per element):

  GENERATED_UI_STRUCTURE 1
  NODE <depth> <key> <kind> [field=<fieldId>] [action=<actionName>]
  PROPERTY <depth> <key> <name> <value>
  ...
  END

Rules the server enforces (all of them are published in the capability text or
returned as a public error reason): <depth> is a non-negative decimal and a child
must follow its parent; <kind> must be a published COMPONENT; <name> must be a
published PROPERTY of that kind; field= must be a published FIELD; action= must
be a published ACTION; the text must end with END; a rejected candidate leaves the
accepted interface unchanged and returns a REASON.

Addressing the accepted controls: a control's caption is for humans only. Two
controls may legitimately share a caption. A driver addresses the accepted control
by its DECLARED key and reads the real accepted geometry from generated-instances;
it never needs the caption to be unique, and the server never required that.

Shared image resources: the application declares the images a generated or a
handwritten interface may use, and the capability text publishes one line per
declaration:
  IMAGE_RESOURCE <key> <type> <version> <name>
Reference one from a published 'image' component by its LOGICAL key and the EXACT
published version - never a local path, URL or handle. The published properties
are 'resource' (STRING key), 'resourceVersion' (INTEGER, a version that key really
declares) and 'contentMode' ('fit' or 'fill'); the shared layout properties apply
as well. The declaration is the single source of truth: an undeclared key or a
withdrawn version is refused as a whole candidate
(REASON image_resource_not_registered / image_resource_version_mismatch) and the
previous accepted interface keeps answering.
PUBLIC
  log "step1b public_interface=$OUT_DIR/public-interface.txt"
}

# --- discovery ---------------------------------------------------------------
if [[ "$MODE" == "discover" ]]; then
  launch_rule
  rule_pub() { python3 "$CLIENT" "$RULE_DESCRIPTOR" "$@"; }
  assert_export_origins "$RULE_STDOUT" rule_generated_consumer
  rule_pub generated-capabilities > "$OUT_DIR/rule-capabilities.txt" 2>&1 || true
  grep -q '^KIND GENERATED_UI_CAPABILITIES' "$OUT_DIR/rule-capabilities.txt" \
    || fail "rule consumer did not answer the capability query"
  rule_pub generated-structure > "$OUT_DIR/rule-structure.txt" 2>&1 || true
  rule_pub generated-fields > "$OUT_DIR/rule-fields.txt" 2>&1 || true
  log "step2 rule_capabilities_bytes=$(wc -c < "$OUT_DIR/rule-capabilities.txt" | tr -d ' ')"

  launch_panel
  panel_pub() { python3 "$CLIENT" "$PANEL_DESCRIPTOR" "$@"; }
  assert_export_origins "$PANEL_STDOUT" second_generated_consumer
  panel_pub generated-capabilities > "$OUT_DIR/panel-capabilities.txt" 2>&1 || true
  grep -q '^KIND GENERATED_UI_CAPABILITIES' "$OUT_DIR/panel-capabilities.txt" \
    || fail "panel consumer did not answer the capability query"
  panel_pub generated-structure > "$OUT_DIR/panel-structure.txt" 2>&1 || true
  panel_pub generated-fields > "$OUT_DIR/panel-fields.txt" 2>&1 || true
  log "step2 panel_capabilities_bytes=$(wc -c < "$OUT_DIR/panel-capabilities.txt" | tr -d ' ')"

  write_public_interface
  say "DISCOVERY OK out=$OUT_DIR rule_capabilities=$OUT_DIR/rule-capabilities.txt panel_capabilities=$OUT_DIR/panel-capabilities.txt"
  finish
fi

# --- apply (model payloads) --------------------------------------------------
[[ -n "$PAYLOADS_DIR" && -d "$PAYLOADS_DIR" ]] || fail "--payloads DIR is required in apply mode"
[[ -f "$OUT_DIR/rule-capabilities.txt" ]] || fail "missing $OUT_DIR/rule-capabilities.txt (run discover first)"
[[ -f "$OUT_DIR/panel-capabilities.txt" ]] || fail "missing $OUT_DIR/panel-capabilities.txt (run discover first)"
for f in rule-generate.txt panel-generate.txt panel-write.txt model-meta.txt; do
  [[ -f "$PAYLOADS_DIR/$f" ]] || fail "model payload missing: $PAYLOADS_DIR/$f"
done
# rule-rearrange.txt / rule-rearrange-version.txt are the model's SECOND turn and
# arrive while the run is paused on real public feedback (see wait_for_model_turn).
for f in rule-generate.txt panel-generate.txt; do
  cp "$PAYLOADS_DIR/$f" "$OUT_DIR/$f"
  log "step2 payload file=$f sha256=$(shasum -a 256 "$PAYLOADS_DIR/$f" | awk '{print $1}') bytes=$(wc -c < "$PAYLOADS_DIR/$f" | tr -d ' ')"
done
cp "$PAYLOADS_DIR/model-meta.txt" "$OUT_DIR/model-meta.txt"
log "step2 model_meta $(tr '\n' ' ' < "$PAYLOADS_DIR/model-meta.txt")"

# LOCAL verifier pre-check of the model's own payload against the PUBLIC
# capability text, before anything is launched. It mirrors ONLY rules the real
# server enforces - published component kinds, published properties of that kind,
# published fields, published actions, the header/END shape and a repeated
# property name - so a payload that uses an unpublished name is reported in the
# same terms as the public protocol instead of being retried silently.
#
# This check is a LOCAL condition, not a server REASON. In particular the
# framework catalog does NOT make `label` required, so a control without a
# caption is legal UI and MUST NOT be rejected for the driver's convenience.
# The two historical `control_without_label` refusals were LOCAL verifier
# conditions; their evidence is left untouched under /private/tmp
# (model-round6-apply.log, model-round6-apply2.log).
precheck_rc=0
python3 - "$PAYLOADS_DIR" "$OUT_DIR" <<'PYCHECK' > "$WORK/payload-precheck.txt" 2>&1 || precheck_rc=$?
import re, sys
payloads, out = sys.argv[1], sys.argv[2]

def parse_capabilities(path):
    kinds, fields, actions = {}, set(), set()
    for line in open(path, encoding="utf-8").read().split("\n"):
        if line.startswith("COMPONENT "):
            kinds.setdefault(line.split(" ")[1], set())
        elif line.startswith("PROPERTY "):
            parts = line.split(" ")
            kinds.setdefault(parts[1], set()).add(parts[2])
        elif line.startswith("FIELD "):
            fields.add(line.split(" ")[1])
        elif line.startswith("ACTION "):
            actions.add(line.split(" ")[1])
    return kinds, fields, actions

def check(payload_path, cap_path, label):
    kinds, fields, actions = parse_capabilities(cap_path)
    text = open(payload_path, encoding="utf-8").read()
    lines = text.split("\n")
    problems = []
    if not lines or lines[0] != "GENERATED_UI_STRUCTURE 1":
        problems.append("invalid_header")
    if "END" not in lines:
        problems.append("missing_end")
    node_kind, seen = {}, {}
    for line in lines:
        m = re.match(r"NODE (\d+) (\S+) (\S+)(?: field=(\S+))?(?: action=(\S+))?$", line)
        if m:
            pos = (m.group(1), m.group(2))
            node_kind[pos] = m.group(3)
            seen[pos] = set()
            if m.group(3) not in kinds:
                problems.append("unknown_component:" + m.group(3))
            if m.group(4) and m.group(4) not in fields:
                problems.append("unknown_field:" + m.group(4))
            if m.group(5) and m.group(5) not in actions:
                problems.append("unknown_action:" + m.group(5))
            continue
        m = re.match(r"PROPERTY (\d+) (\S+) (\S+)(?: (.*))?$", line)
        if m:
            pos = (m.group(1), m.group(2))
            name = m.group(3)
            if name in seen.get(pos, set()):
                problems.append("duplicate_property:" + m.group(2) + "." + name)
            seen.setdefault(pos, set()).add(name)
            kind = node_kind.get(pos)
            if kind is not None and name not in kinds.get(kind, set()):
                problems.append("unknown_property:" + m.group(2) + "." + name)
    if problems:
        print("MODEL_PAYLOAD_REJECTED %s %s" % (label, ",".join(sorted(set(problems)))))
        sys.exit(1)
    print("MODEL_PAYLOAD_OK %s bytes=%d" % (label, len(text.encode())))

for payload, cap, label in (("rule-generate.txt", "rule-capabilities.txt", "rule_generate"),
                            ("panel-generate.txt", "panel-capabilities.txt", "panel_generate")):
    check("%s/%s" % (payloads, payload), "%s/%s" % (out, cap), label)
PYCHECK
if (( precheck_rc != 0 )); then
  cat "$WORK/payload-precheck.txt" >> "$LOG" || true
  fail "the model payload failed the LOCAL verifier pre-check (mirrors public protocol rules) ($(tr '\n' ' ' < "$WORK/payload-precheck.txt"))"
fi
while IFS= read -r line; do log "step2b $line"; done < "$WORK/payload-precheck.txt"

# --- rule domain -------------------------------------------------------------
launch_rule
rule_pub() { python3 "$CLIENT" "$RULE_DESCRIPTOR" "$@"; }
assert_export_origins "$RULE_STDOUT" rule_generated_consumer

rule_field_token() { # rule_field_token <fieldId> <TOKEN>
  local attempt=0 line value
  while (( attempt < 12 )); do
    line="$(rule_pub generated-fields 2>/dev/null | grep "^FIELD $1 " | head -1 || true)"
    if [[ -n "$line" ]]; then
      value="$(print -r -- "$line" | awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}')"
      [[ -n "$value" ]] && { print -r -- "$value"; return 0; }
    fi
    sleep 0.3
    attempt=$(( attempt + 1 ))
  done
  return 1
}
rule_structure_version() { rule_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
poll_rule_version() { # poll_rule_version <expected>
  local waited=0 v=""
  while (( waited < 40 )); do
    v="$(rule_structure_version)"
    [[ "$v" == "$1" ]] && { print -r -- "$v"; return 0; }
    sleep 0.5
    waited=$(( waited + 1 ))
  done
  print -r -- "$v"
  return 1
}

# The generated editors bind to the SELECTED record, so the public client first
# creates and selects one exactly as a consumer would.
rule_pub invoke 0 CREATE_RECORD --target 8000 --arg label=STRING:"模型消费记录" --arg enabled=BOOLEAN:true \
  --arg retentionCount=INTEGER:7 --arg excludedType=STRING:"-" --arg requestId=STRING:"model-rule-1" \
  > "$WORK/rule-create.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-create.log" || fail "rule record create failed"
RULE_RECORD_ID="$(rule_pub get 2>/dev/null | awk '/FIELD [0-9]+ label STRING/{print $2; exit}')"
[[ -n "$RULE_RECORD_ID" ]] || fail "rule record id missing"
rule_pub invoke "$(rule_pub get 2>/dev/null | awk '/^VERSION /{print $2}')" SELECT_RECORD \
  --target "$RULE_RECORD_ID" > "$WORK/rule-select.log" 2>&1 || true
grep -q '^APPLIED true' "$WORK/rule-select.log" || fail "rule record select failed"
log "step3 rule_record_ready id=$RULE_RECORD_ID"

# step3a: the MODEL's own structure, submitted at version 0.
rule_pub generated-submit --structure-version 0 --payload-file "$OUT_DIR/rule-generate.txt" \
  > "$WORK/rule-submit-1.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/rule-submit-1.log" || {
  log "model_payload_submit reason=$(grep '^REASON ' "$WORK/rule-submit-1.log" | head -1)"
  fail "the model's rule structure was rejected"
}
RULE_VERSION="$(poll_rule_version 1)" || fail "model rule structure was never scene-accepted (version=$RULE_VERSION)"
log "step3a rule_model_structure_accepted version=$RULE_VERSION payload=rule-generate.txt"

# Which editor/action did the model declare? Read them from the model's own
# payload - the script has no hardcoded candidate. The SAME function is used
# again on the rearranged payload, because the accepted structure at the time of
# the desktop press is the rearranged one.
model_rule_targets() { # model_rule_targets <payload-file> -> 3 tab-separated lines
  python3 - "$1" <<'PYTARGET'
import re, sys
lines = open(sys.argv[1], encoding="utf-8").read().split("\n")
props, nodes = {}, []
for line in lines:
    m = re.match(r"NODE (\d+) (\S+) (\S+)(?: field=(\S+))?(?: action=(\S+))?$", line)
    if m:
        nodes.append((m.group(2), m.group(3), m.group(4) or "", m.group(5) or ""))
        continue
    m = re.match(r"PROPERTY (\d+) (\S+) (\S+)(?: (.*))?$", line)
    if m:
        props[(m.group(2), m.group(3))] = m.group(4)
editors = [(k, f, props.get((k, "label"), "")) for (k, kind, f, a) in nodes
           if kind in ("textInput", "integerInput") and f and props.get((k, "label"), "")]
actions = [(k, a, props.get((k, "label"), "")) for (k, kind, f, a) in nodes
           if kind == "action" and a and props.get((k, "label"), "")]
if not editors or not actions:
    print("MISSING")
    sys.exit(1)
print("\t".join(editors[0]))
print("\t".join(actions[0]))
print("\t".join(editors[1]) if len(editors) > 1 else "-\t-\t-")
PYTARGET
}
MODEL_TARGETS="$(model_rule_targets "$OUT_DIR/rule-generate.txt")" \
  || fail "the model's rule payload declares no captioned editable field editor and action element"
RULE_EDIT_FIELD="$(print -r -- "$MODEL_TARGETS" | sed -n '1p' | cut -f2)"
RULE_EDIT_LABEL="$(print -r -- "$MODEL_TARGETS" | sed -n '1p' | cut -f3)"
RULE_ACTION_KEY="$(print -r -- "$MODEL_TARGETS" | sed -n '2p' | cut -f1)"
RULE_ACTION_LABEL="$(print -r -- "$MODEL_TARGETS" | sed -n '2p' | cut -f3)"
RULE_EDIT2_FIELD="$(print -r -- "$MODEL_TARGETS" | sed -n '3p' | cut -f2)"
RULE_EDIT2_LABEL="$(print -r -- "$MODEL_TARGETS" | sed -n '3p' | cut -f3)"
[[ -n "$RULE_EDIT_FIELD" && -n "$RULE_EDIT_LABEL" && -n "$RULE_ACTION_LABEL" ]] \
  || fail "model rule payload metadata incomplete: '$MODEL_TARGETS'"
log "step3b model_declared editor_field=$RULE_EDIT_FIELD editor_label='$RULE_EDIT_LABEL' action_label='$RULE_ACTION_LABEL' second_editor=${RULE_EDIT2_FIELD} second_label='$RULE_EDIT2_LABEL'"

# The generated key the model's own payload binds to one field. A structure may
# bind the same field from more than one control (a composite element and a plain
# editor), so the exact accepted key is passed to the shared input driver instead
# of letting it guess from a caption.
model_field_key() { # model_field_key <payload-file> <fieldId>
  awk -v wanted="$2" '
    /^NODE / {
      key = $3
      for (i = 1; i <= NF; i++) {
        if ($i == "field=" wanted) { print key; exit }
      }
    }' "$1"
}

# step3c: real desktop input into the model's own editor.
# A runtime-generated, unique legal value: the model never sees it in advance.
RULE_MODEL_TEXT="model-value-${RUN_TAG}"
RULE_EDIT_VERIFIED="false"
if [[ -z "$INPUT_BLOCKED" ]]; then
  prepare_desktop_driver || INPUT_BLOCKED="${INPUT_BLOCKED:-driver_unavailable}"
fi
if [[ -z "$INPUT_BLOCKED" ]]; then
  AX_PID="$RULE_PID"
  RULE_EDIT_KEY="$(model_field_key "$OUT_DIR/rule-generate.txt" "$RULE_EDIT_FIELD")"
  if real_generated_text_edit model_rule_edit "$RULE_DESCRIPTOR" "$RULE_EDIT_FIELD" "$RULE_EDIT_LABEL" \
      "text field" "$RULE_MODEL_TEXT" "${RULE_EDIT_KEY:--}"; then
    RULE_EDIT_VERIFIED="true"
    log "step3c rule_model_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' target='$RULE_MODEL_TEXT' input=real_desktop_control driver=cgevent"
  else
    blocked model_rule_edit generated_editor_input_not_delivered
    log "FAIL_CANDIDATE model_rule_edit label='$RULE_EDIT_LABEL' before='${REAL_EDIT_BEFORE:-}' after='${REAL_EDIT_AFTER:-}'"
  fi
else
  blocked model_rule_edit "$INPUT_BLOCKED"
fi
if [[ "$RULE_EDIT_VERIFIED" == "true" ]]; then
  [[ "$(rule_field_token "$RULE_EDIT_FIELD" DRAFT_HEX | hex_to_text)" == "$RULE_MODEL_TEXT" ]] \
    || fail "the model-declared editor did not write the owner draft"
  log "step3c rule_model_edit_readback exact=true"
else
  log "note rule_model_edit_readback not_verified desktop_input_blocked=true"
fi
# The value the model's next turn must depend on is the field's REAL current
# content. When desktop input was blocked the verifier's intended text never
# reached the owner, so the live value is what the public projection really
# reports - never the text the verifier merely wanted to type.
if [[ "$RULE_EDIT_VERIFIED" == "true" ]]; then
  RULE_LIVE_VALUE="$RULE_MODEL_TEXT"
  RULE_LIVE_SOURCE="desktop_input"
else
  RULE_LIVE_VALUE="$(rule_field_token "$RULE_EDIT_FIELD" DRAFT_HEX | hex_to_text)"
  RULE_LIVE_SOURCE="captured_without_desktop_input"
fi
[[ -n "$RULE_LIVE_VALUE" ]] || fail "the live field value could not be read for the model's next turn"
log "step3c-live rule_live_value='$RULE_LIVE_VALUE' source=$RULE_LIVE_SOURCE"

# step3d: a STALE submit of the model's own payload is refused by the public
# error, the old interface keeps answering, and the same payload then succeeds at
# the version the public read-back reports.
rule_pub generated-submit --structure-version 0 --payload-file "$OUT_DIR/rule-generate.txt" \
  > "$WORK/rule-submit-stale.log" 2>&1 || true
grep -q '^APPLIED false' "$WORK/rule-submit-stale.log" || fail "the stale-version submit was not refused"
STALE_REASON="$(grep '^REASON ' "$WORK/rule-submit-stale.log" | head -1 | awk '{print $2}')"
[[ "$STALE_REASON" == "structure_version_conflict" ]] || fail "stale submit reason was '$STALE_REASON', not structure_version_conflict"
if [[ "$RULE_EDIT_VERIFIED" == "true" ]]; then
  [[ "$(rule_field_token "$RULE_EDIT_FIELD" DRAFT_HEX | hex_to_text)" == "$RULE_MODEL_TEXT" ]] \
    || fail "the old interface stopped answering after the refused stale submit"
fi
log "step3d stale_submit_refused reason=$STALE_REASON old_interface_interactive=$(rule_pub generated-structure >/dev/null 2>&1 && print true || print false)"

# step3e: the model's rearrangement, submitted at the current public version.
CURRENT_RULE_VERSION="$(rule_structure_version)"
[[ -n "$CURRENT_RULE_VERSION" ]] || fail "could not read the current structure version"

# --- the model's SECOND turn is driven by what really happened --------------
# Nothing here rewrites the version on the model's behalf: the model receives the
# live value it must depend on, the public refusal above and the CURRENT version,
# and its own reply must state the version it submits at.
rule_pub generated-instances > "$OUT_DIR/rule-instances-after-stale.txt" 2>&1 || true
rule_pub generated-structure > "$OUT_DIR/rule-structure-for-model.txt" 2>&1 || true
# The consistent snapshot is the public feedback bundle: one atomic read with
# the cursor, the separated owner/scene facts and the sections, so the model
# decides from ONE generation instead of a set of independently read pieces.
rule_pub generated-snapshot > "$OUT_DIR/rule-snapshot-for-model.txt" 2>&1 || true
cat > "$OUT_DIR/model-feedback.txt" <<FEEDBACK
The next decision must use these REAL values (not what you assumed).
FIELD_TO_KEEP field=${RULE_EDIT_FIELD} label='${RULE_EDIT_LABEL}' value='${RULE_LIVE_VALUE}' draft_version=$(rule_field_token "$RULE_EDIT_FIELD" VERSION)
STRUCTURE_VERSION ${CURRENT_RULE_VERSION}
STALE_SUBMIT_REFUSED reason=structure_version_conflict attempted_version=0
YOUR_FIRST_PAYLOAD:
$(cat "$OUT_DIR/rule-generate.txt" 2>/dev/null || true)
ACCEPTED_STRUCTURE:
$(cat "$OUT_DIR/rule-structure-for-model.txt" 2>/dev/null || true)
ACCEPTED_INSTANCES:
$(cat "$OUT_DIR/rule-instances-after-stale.txt" 2>/dev/null || true)
PUBLIC_SNAPSHOT (ONE atomic read: cursor + owner/scene facts + sections):
$(cat "$OUT_DIR/rule-snapshot-for-model.txt" 2>/dev/null || true)
Required reply files (write BOTH):
  rule-rearrange.txt           a complete GENERATED_UI_STRUCTURE ending with END that
                               KEEPS the live field value '${RULE_LIVE_VALUE}' somewhere in its
                               text, rearranges/extends the panel and stays inside the
                               published capability text
  rule-rearrange-version.txt   the structure version you choose to submit at, as one integer
FEEDBACK
log "AWAITING_MODEL_TURN feedback=$OUT_DIR/model-feedback.txt value='$RULE_LIVE_VALUE' source=$RULE_LIVE_SOURCE current_version=$CURRENT_RULE_VERSION"
waited_model=0
while (( waited_model < 900 )); do
  if [[ -f "$PAYLOADS_DIR/rule-rearrange.txt" && -f "$PAYLOADS_DIR/rule-rearrange-version.txt" ]]; then
    break
  fi
  sleep 2
  waited_model=$(( waited_model + 2 ))
done
[[ -f "$PAYLOADS_DIR/rule-rearrange.txt" && -f "$PAYLOADS_DIR/rule-rearrange-version.txt" ]] \
  || fail "the model's second turn did not arrive (feedback in $OUT_DIR/model-feedback.txt)"
cp "$PAYLOADS_DIR/rule-rearrange.txt" "$OUT_DIR/rule-rearrange.txt"
cp "$PAYLOADS_DIR/rule-rearrange-version.txt" "$OUT_DIR/rule-rearrange-version.txt"
# The model's chosen version is parsed STRICTLY and used VERBATIM when valid:
# read the file once, strip ONLY leading/trailing whitespace, and require the
# ENTIRE remainder to be one non-negative decimal integer. `tr -d '[:space:]'`
# used to glue `1 2` / two lines into `12` and to accept `-1`/`1x`; internal
# whitespace, several tokens, a sign, a suffix or an empty file is now REJECTED
# with a machine-readable reason and is never repaired or cleaned.
model_version_strict() { # model_version_strict <raw-text> -> version, or return 1
  local stripped="${1#"${1%%[![:space:]]*}"}"
  stripped="${stripped%"${stripped##*[![:space:]]}"}"
  [[ -n "$stripped" && "$stripped" == <-> ]] || return 1
  print -r -- "$stripped"
}
MODEL_VERSION_RAW="$(cat "$PAYLOADS_DIR/rule-rearrange-version.txt")"
if ! MODEL_CHOSEN_VERSION="$(model_version_strict "$MODEL_VERSION_RAW")"; then
  MODEL_VERSION_RAW_HEX="$(printf '%s' "$MODEL_VERSION_RAW" | od -An -tx1 | tr -d ' \n')"
  fail "MODEL_VERSION_REJECTED reason=version_not_single_non_negative_decimal_integer raw_hex=$MODEL_VERSION_RAW_HEX"
fi
[[ "$MODEL_CHOSEN_VERSION" == "$CURRENT_RULE_VERSION" ]] \
  || fail "the model chose a stale version ($MODEL_CHOSEN_VERSION) after being told $CURRENT_RULE_VERSION"
log "step3e model_second_turn version=$MODEL_CHOSEN_VERSION payload_bytes=$(wc -c < "$OUT_DIR/rule-rearrange.txt" | tr -d ' ')"
precheck2_rc=0
python3 - "$OUT_DIR/rule-rearrange.txt" "$OUT_DIR/rule-capabilities.txt" \
  > "$WORK/payload-precheck-2.txt" 2>&1 <<'PYCHECK2' || precheck2_rc=$?
import re, sys
payload, capability = sys.argv[1], sys.argv[2]
kinds, props, fields, actions = {}, {}, set(), set()
for line in open(capability, encoding="utf-8").read().split("\n"):
    if line.startswith("COMPONENT "):
        kinds.setdefault(line.split(" ")[1], set())
    elif line.startswith("PROPERTY "):
        parts = line.split(" ")
        kinds.setdefault(parts[1], set()).add(parts[2])
    elif line.startswith("FIELD "):
        fields.add(line.split(" ")[1])
    elif line.startswith("ACTION "):
        actions.add(line.split(" ")[1])
problems = []
lines = open(payload, encoding="utf-8").read().split("\n")
if not lines or lines[0] != "GENERATED_UI_STRUCTURE 1":
    problems.append("invalid_header")
if "END" not in lines:
    problems.append("missing_end")
seen = {}
node_kind = {}
for line in lines:
    m = re.match(r"NODE (\d+) (\S+) (\S+)(?: field=(\S+))?(?: action=(\S+))?$", line)
    if m:
        pos = (m.group(1), m.group(2))
        node_kind[pos] = m.group(3)
        seen[pos] = set()
        if m.group(3) not in kinds:
            problems.append("unknown_component:" + m.group(3))
        if m.group(4) and m.group(4) not in fields:
            problems.append("unknown_field:" + m.group(4))
        if m.group(5) and m.group(5) not in actions:
            problems.append("unknown_action:" + m.group(5))
        continue
    m = re.match(r"PROPERTY (\d+) (\S+) (\S+)(?: (.*))?$", line)
    if m:
        pos = (m.group(1), m.group(2))
        name = m.group(3)
        if name in seen.get(pos, set()):
            problems.append("duplicate_property:" + m.group(2) + "." + name)
        seen.setdefault(pos, set()).add(name)
        kind = node_kind.get(pos)
        if kind is not None and name not in kinds.get(kind, set()):
            problems.append("unknown_property:" + m.group(2) + "." + name)
if problems:
    print("MODEL_PAYLOAD_REJECTED rule_rearrange_turn2 " + ",".join(sorted(set(problems))))
    sys.exit(1)
print("MODEL_PAYLOAD_OK rule_rearrange_turn2 bytes=%d" % len(open(payload, "rb").read()))
PYCHECK2
if (( precheck2_rc != 0 )); then
  cat "$WORK/payload-precheck-2.txt" >> "$LOG" 2>&1 || true
  fail "the model's second-turn payload failed the LOCAL verifier pre-check (mirrors public protocol rules)"
fi
while IFS= read -r line; do log "step3e-b $line"; done < "$WORK/payload-precheck-2.txt"

rule_pub generated-submit --structure-version "$CURRENT_RULE_VERSION" --payload-file "$OUT_DIR/rule-rearrange.txt" \
  > "$WORK/rule-submit-2.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/rule-submit-2.log" || {
  log "model_rearrange_submit reason=$(grep '^REASON ' "$WORK/rule-submit-2.log" | head -1)"
  fail "the model's rearranged structure was rejected"
}
RULE_VERSION2="$(poll_rule_version "$(( CURRENT_RULE_VERSION + 1 ))")" \
  || fail "the model's rearrangement was never scene-accepted (version=$RULE_VERSION2)"
log "step3e rule_model_rearrange_accepted version=$RULE_VERSION2 payload=rule-rearrange.txt"

# The rearrangement must be visible in the public structure read-back, and the
# draft written through the model's own editor must have survived it.
rule_pub generated-structure > "$OUT_DIR/rule-structure-after.txt" 2>&1 || true
# The second turn must DEPEND on the live value it was given: the accepted
# structure has to carry the exact text the human typed at runtime. A reply that
# merely reorders the old panel fails here instead of passing as "continued".
grep -qF "$RULE_LIVE_VALUE" "$OUT_DIR/rule-structure-after.txt" \
  || fail "the model's second turn does not carry the live value '$RULE_LIVE_VALUE'"
log "step3e-c model_turn_depends_on_live_value value='$RULE_LIVE_VALUE' source=$RULE_LIVE_SOURCE present=true"
MODEL_KEYS="$(python3 - "$OUT_DIR/rule-rearrange.txt" <<'PYKEYS'
import re, sys
keys = []
for line in open(sys.argv[1], encoding="utf-8"):
    m = re.match(r"NODE \d+ (\S+) ", line)
    if m:
        keys.append(m.group(1))
print(" ".join(keys))
PYKEYS
)"
for key in ${=MODEL_KEYS}; do
  grep -q "NODE [0-9]* $key " "$OUT_DIR/rule-structure-after.txt" \
    || fail "accepted structure is missing the model's node $key"
done
if [[ "$RULE_EDIT_VERIFIED" == "true" ]]; then
  [[ "$(rule_field_token "$RULE_EDIT_FIELD" DRAFT_HEX | hex_to_text)" == "$RULE_MODEL_TEXT" ]] \
    || fail "the rearrangement dropped the draft written through the model's editor"
fi
log "step3f rearrange_visible=true nodes=${MODEL_KEYS} draft_preserved=$( [[ "$RULE_EDIT_VERIFIED" == "true" ]] && print verified || print input_blocked )"

# The accepted structure is now the REARRANGED one, so the action element and the
# continuation editor are re-read from that payload: pressing a caption that only
# existed in the first structure would not be this structure's control.
REARRANGE_TARGETS="$(model_rule_targets "$OUT_DIR/rule-rearrange.txt")" \
  || fail "the model's rearranged payload declares no captioned action element"
RULE_ACTION_KEY="$(print -r -- "$REARRANGE_TARGETS" | sed -n '2p' | cut -f1)"
RULE_ACTION_LABEL="$(print -r -- "$REARRANGE_TARGETS" | sed -n '2p' | cut -f3)"
REARRANGE_EDIT2_FIELD="$(print -r -- "$REARRANGE_TARGETS" | sed -n '3p' | cut -f2)"
REARRANGE_EDIT2_LABEL="$(print -r -- "$REARRANGE_TARGETS" | sed -n '3p' | cut -f3)"
[[ -n "$RULE_ACTION_LABEL" ]] || fail "the rearranged payload declares no captioned action element"
if [[ -n "$REARRANGE_EDIT2_FIELD" && "$REARRANGE_EDIT2_FIELD" != "-" ]]; then
  RULE_EDIT2_FIELD="$REARRANGE_EDIT2_FIELD"
  RULE_EDIT2_LABEL="$REARRANGE_EDIT2_LABEL"
fi
log "step3f rearrange_targets action_label='$RULE_ACTION_LABEL' continue_editor=${RULE_EDIT2_FIELD} continue_label='$RULE_EDIT2_LABEL'"

# step3g: real press on the MODEL's own action element, then read the owner.
#
# The AX press matches a control by its declared caption, and the handwritten part
# of this window already contains controls captioned 应用草稿/取消草稿. Before
# pressing, count how many of the window's AX controls carry the model's caption:
# only a unique caption proves that the pressed control is the generated one, so
# an ambiguous caption is reported as BLOCKED instead of being claimed.
ax_label_lines() { # ax_label_lines <pid> <label> -> matching "description|title|name" button lines
  local pid="$1" label="$2"
  cjgui_ax 15 -e "tell application \"System Events\"
    tell (first process whose unix id is $pid)
      set out to \"\"
      repeat with b in (buttons of window 1)
        set out to out & (description of b) & \"|\" & (title of b) & \"|\" & (name of b) & \"\n\"
      end repeat
      return out
    end tell
  end tell" 2>/dev/null \
    | awk -F'|' -v want="$label" 'NF >= 3 && ($1 == want || $2 == want || $3 == want) { print }' | tr '\n' ';'
}
ax_label_count() { # ax_label_count <pid> <label> -> number of AX BUTTONS carrying label
  # Each output line is one button: "description|title|name". The bridge publishes
  # the caption through several attributes, so counting matching FIELDS would
  # triple one button; count matching LINES, i.e. real buttons.
  local pid="$1" label="$2" count
  count="$(cjgui_ax 15 -e "tell application \"System Events\"
    tell (first process whose unix id is $pid)
      set out to \"\"
      repeat with b in (buttons of window 1)
        set out to out & (description of b) & \"|\" & (title of b) & \"|\" & (name of b) & \"\n\"
      end repeat
      return out
    end tell
  end tell" 2>/dev/null \
    | awk -F'|' -v want="$label" 'NF >= 3 && ($1 == want || $2 == want || $3 == want) { n += 1 } END { print n + 0 }')"
  print -r -- "${count:-0}"
}
# The accepted instance of one declared key, from the public projection.
# real_focus_activate_identity <label> <descriptor> <semanticId> <keycode> <maxTabs>
# Real Tab walk until the window reports that the ACCEPTED instance identity owns
# the focus, then a real key press. The identity comes from the public instance
# projection (declared key -> accepted semantic id), so a same-caption handwritten
# control can never be selected by this path.
real_focus_activate_identity() {
  local label="$1" descriptor="$2" semantic="$3" keycode="$4" maxTabs="$5"
  local i=0 focus=""
  activate_app
  make_window_key || true
  while (( i < maxTabs )); do
    focus="$(window_focus_for "$descriptor")"
    if [[ "$focus" == "$semantic" ]]; then
      drive key "$keycode"
      sleep 0.8
      log "diag focus_activate label=$label semantic=$semantic tabs=$i"
      return 0
    fi
    drive tab
    sleep 0.25
    i=$(( i + 1 ))
  done
  log "diag focus_activate_no_match label=$label semantic=$semantic tabs=$i last_focus='$focus'"
  return 1
}
rule_instance_field() { # rule_instance_field <key> <token-name>
  rule_pub generated-instances 2>/dev/null \
    | awk -v k="$1" -v f="$2" '$1 == "INSTANCE" && $2 == k {
        for (i = 1; i <= NF; i++) if (index($i, f "=") == 1) { sub("^" f "=", "", $i); print $i; exit }
      }'
}
if [[ -z "$INPUT_BLOCKED" ]]; then
  AX_PID="$RULE_PID"
  # Address the model's own control by its DECLARED key and the geometry the
  # window really accepted - never by its caption. Same-name controls are legal
  # UI; a caption is not an identity. The caption-collision count is recorded as
  # an environment fact, not treated as a protocol refusal.
  # Address the model's own control by the accepted INSTANCE IDENTITY the public
  # projection publishes for its declared key (its semantic id), not by a caption:
  # the window already walks focus by that identity, and same-caption controls are
  # legal UI. A caption collision is recorded as an environment fact only.
  RULE_ACTION_INSTANCE="$(rule_instance_field "$RULE_ACTION_KEY" semantic)"
  RULE_ACTION_BOUNDS="$(rule_instance_field "$RULE_ACTION_KEY" bounds)"
  RULE_ACTION_CAPTION_MATCHES="$(ax_label_count "$RULE_PID" "$RULE_ACTION_LABEL")"
  log "step3g rule_model_action_address key='$RULE_ACTION_KEY' accepted_semantic='${RULE_ACTION_INSTANCE:-missing}' accepted_bounds='${RULE_ACTION_BOUNDS:-missing}' caption='$RULE_ACTION_LABEL' same_caption_controls=$RULE_ACTION_CAPTION_MATCHES (captions are not identity)"
  if [[ -z "$RULE_ACTION_INSTANCE" ]]; then
    blocked model_rule_action_press "accepted_instance_identity_missing"
    log "FAIL_CANDIDATE model_rule_action_press key='$RULE_ACTION_KEY' projection='$(rule_pub generated-instances 2>/dev/null | tr '\n' ';')'"
  elif real_focus_activate_identity "model_rule_action" "$RULE_DESCRIPTOR" "$RULE_ACTION_INSTANCE" 49 120; then
    log "step3g rule_model_action_press key='$RULE_ACTION_KEY' semantic='$RULE_ACTION_INSTANCE' located_by=accepted_identity focus_activated=true keycode=space input=real_desktop_control driver=cgevent"
  else
    blocked model_rule_action_press "accepted_identity_not_reachable_by_focus semantic='$RULE_ACTION_INSTANCE'"
    log "FAIL_CANDIDATE model_rule_action_press key='$RULE_ACTION_KEY' semantic='$RULE_ACTION_INSTANCE' last_focus='$(window_focus_for "$RULE_DESCRIPTOR")'"
  fi
else
  blocked model_rule_action_press "$INPUT_BLOCKED"
fi
APPLIED_TEXT="$(rule_field_token "$RULE_EDIT_FIELD" APPLIED_HEX | hex_to_text)"
if [[ -n "$BLOCKED_DESKTOP" ]]; then
  [[ -n "$APPLIED_TEXT" ]] || fail "the owner applied value disappeared"
  log "note model_rule_action_readback applied='$APPLIED_TEXT' control_input_unverified=true"
else
  [[ "$APPLIED_TEXT" == "$RULE_MODEL_TEXT" ]] \
    || fail "the model's action did not apply the draft written through its editor (applied='$APPLIED_TEXT')"
  log "step3g rule_model_action_applied applied='$APPLIED_TEXT'"
fi

# step3h: the public TYPE and RANGE decide the legal continuation value, a real
# desktop input writes it, and the exact read-back goes BACK to the model for one
# dependent confirmation. The old fixed text token was typed into whatever the
# model had declared, including an INTEGER editor, and nothing was ever fed back.
if [[ -n "$RULE_EDIT2_FIELD" && "$RULE_EDIT2_FIELD" != "-" ]]; then
  EDIT2_SPEC="$(awk -v id="$RULE_EDIT2_FIELD" '$1 == "FIELD" && $2 == id {print; exit}' "$OUT_DIR/rule-capabilities.txt")"
  [[ -n "$EDIT2_SPEC" ]] || fail "the continuation field $RULE_EDIT2_FIELD is not published"
  EDIT2_KIND="$(print -r -- "$EDIT2_SPEC" | awk '{print $3}')"
  EDIT2_MIN="$(print -r -- "$EDIT2_SPEC" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^min=/) {sub(/^min=/, "", $i); print $i; exit}}')"
  EDIT2_MAX="$(print -r -- "$EDIT2_SPEC" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^max=/) {sub(/^max=/, "", $i); print $i; exit}}')"
  EDIT2_INPUT="$(print -r -- "$EDIT2_SPEC" | awk '{for (i = 1; i <= NF; i++) if ($i ~ /^input=/) {sub(/^input=/, "", $i); print $i; exit}}')"
  EDIT2_MIN="${EDIT2_MIN:-0}"; EDIT2_MAX="${EDIT2_MAX:-0}"
  case "$EDIT2_KIND" in
    INTEGER)
      # A value the published range really allows; never a text token.
      if (( EDIT2_MAX > EDIT2_MIN )); then
        RULE_MODEL_TEXT2="$EDIT2_MAX"
      elif (( EDIT2_MIN > 0 )); then
        RULE_MODEL_TEXT2="$EDIT2_MIN"
      else
        RULE_MODEL_TEXT2="7"
      fi
      ;;
    BOOLEAN)
      RULE_MODEL_TEXT2="-"
      ;;
    *)
      RULE_MODEL_TEXT2="模型续写-丁"
      ;;
  esac
  log "step3h rule_model_continue_plan field=$RULE_EDIT2_FIELD kind=$EDIT2_KIND input=$EDIT2_INPUT range=[$EDIT2_MIN,$EDIT2_MAX] legal_value='$RULE_MODEL_TEXT2'"
  if [[ -z "$INPUT_BLOCKED" ]]; then
    AX_PID="$RULE_PID"
    if [[ "$EDIT2_KIND" == "BOOLEAN" ]]; then
      if real_generated_boolean_toggle model_rule_edit_two "$RULE_DESCRIPTOR" "$RULE_EDIT2_FIELD" "$RULE_EDIT2_LABEL"; then
        RULE_CONTINUE_VALUE="$REAL_EDIT_AFTER"
        log "step3h rule_model_continue_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
      else
        blocked model_rule_continue_edit second_generated_editor_not_delivered
      fi
    elif RULE_EDIT2_KEY="$(model_field_key "$OUT_DIR/rule-rearrange.txt" "$RULE_EDIT2_FIELD")" && \
        real_generated_text_edit model_rule_edit_two "$RULE_DESCRIPTOR" "$RULE_EDIT2_FIELD" "$RULE_EDIT2_LABEL" \
        "text field" "$RULE_MODEL_TEXT2" "${RULE_EDIT2_KEY:--}"; then
      log "step3h rule_model_continue_edit mode='$REAL_EDIT_MODE' before='$REAL_EDIT_BEFORE' after='$REAL_EDIT_AFTER' input=real_desktop_control driver=cgevent"
      RULE_CONTINUE_VALUE="$(rule_field_token "$RULE_EDIT2_FIELD" DRAFT_HEX | hex_to_text)"
      [[ "$RULE_CONTINUE_VALUE" == "$RULE_MODEL_TEXT2" ]] \
        || fail "the desktop continuation after the apply did not reach the owner exactly ('$RULE_CONTINUE_VALUE')"
      log "step3h rule_model_continue_readback exact=true value='$RULE_CONTINUE_VALUE'"
    else
      blocked model_rule_continue_edit second_generated_editor_not_delivered
    fi
  else
    blocked model_rule_continue_edit "$INPUT_BLOCKED"
  fi

  if [[ -n "${RULE_CONTINUE_VALUE:-}" ]]; then
    # The model reads the FINAL exact value through the same public surface and
    # must answer with one decision that depends on it. Nothing edits the value
    # on the model's behalf and no assumed value is accepted.
    RULE_CONTINUE_APPLIED="$(rule_field_token "$RULE_EDIT2_FIELD" APPLIED_HEX | hex_to_text)"
    rule_pub generated-snapshot > "$OUT_DIR/rule-snapshot-after-continuation.txt" 2>&1 || true
    {
      print -r -- "The owner read-back of the continuation edit is EXACT (nothing was assumed):"
      print -r -- "FIELD field=$RULE_EDIT2_FIELD kind=$EDIT2_KIND input=$EDIT2_INPUT published_range=[$EDIT2_MIN,$EDIT2_MAX] value='$RULE_CONTINUE_VALUE' applied='$RULE_CONTINUE_APPLIED'"
      print -r -- "EARLIER_FIELD field=$RULE_EDIT_FIELD value='$(rule_field_token "$RULE_EDIT_FIELD" DRAFT_HEX | hex_to_text)'"
      print -r -- "STRUCTURE_VERSION $(rule_structure_version)"
      print -r -- "PUBLIC_SNAPSHOT (ONE atomic read: cursor + owner/scene facts + sections):"
      cat "$OUT_DIR/rule-snapshot-after-continuation.txt" 2>/dev/null || true
      print -r -- "Required reply file (write ONE):"
      print -r -- "  rule-confirm.txt   one decision line that DEPENDS on the exact value above:"
      print -r -- "                     CONFIRM field=<fieldId> value=<the exact value above>"
      print -r -- "                     or REJECT field=<fieldId> reason=<why>"
    } > "$OUT_DIR/model-confirm-feedback.txt"
    log "AWAITING_MODEL_CONFIRM feedback=$OUT_DIR/model-confirm-feedback.txt value='$RULE_CONTINUE_VALUE' applied='$RULE_CONTINUE_APPLIED'"
    waited_confirm=0
    while (( waited_confirm < 600 )); do
      [[ -f "$PAYLOADS_DIR/rule-confirm.txt" ]] && break
      sleep 2
      waited_confirm=$(( waited_confirm + 2 ))
    done
    [[ -f "$PAYLOADS_DIR/rule-confirm.txt" ]] \
      || fail "the model confirmation did not arrive (feedback in $OUT_DIR/model-confirm-feedback.txt)"
    cp "$PAYLOADS_DIR/rule-confirm.txt" "$OUT_DIR/rule-confirm.txt"
    grep -qF "field=$RULE_EDIT2_FIELD" "$OUT_DIR/rule-confirm.txt" \
      || fail "the model confirmation does not name the continuation field"
    grep -qF "$RULE_CONTINUE_VALUE" "$OUT_DIR/rule-confirm.txt" \
      || fail "the model confirmation does not depend on the exact read-back value"
    log "step3h model_confirm_ok bytes=$(wc -c < "$OUT_DIR/rule-confirm.txt" | tr -d ' ') value='$RULE_CONTINUE_VALUE' reply='$(tr '\n' ' ' < "$OUT_DIR/rule-confirm.txt")'"
  fi
else
  log "note rule_model_continue_edit no_second_editor_declared (the model declared one editor)"
fi

# --- second domain: the SAME public client, no rule-specific scripting -------
launch_panel
panel_pub() { python3 "$CLIENT" "$PANEL_DESCRIPTOR" "$@"; }
assert_export_origins "$PANEL_STDOUT" second_generated_consumer
panel_structure_version() { panel_pub generated-structure 2>/dev/null | awk '/^STRUCTURE_VERSION /{print $2}'; }
panel_field_token() { # panel_field_token <fieldId> <TOKEN>
  local attempt=0 line value
  while (( attempt < 12 )); do
    line="$(panel_pub generated-fields 2>/dev/null | grep "^FIELD $1 " | head -1 || true)"
    if [[ -n "$line" ]]; then
      value="$(print -r -- "$line" | awk -v tag="$2" '{for (i = 1; i <= NF; i++) if ($i == tag) print $(i + 1)}')"
      [[ -n "$value" ]] && { print -r -- "$value"; return 0; }
    fi
    sleep 0.3
    attempt=$(( attempt + 1 ))
  done
  return 1
}
panel_pub generated-submit --structure-version 0 --payload-file "$OUT_DIR/panel-generate.txt" \
  > "$WORK/panel-submit.log" 2>&1 || true
grep -q '^CANDIDATE_ACCEPTED true' "$WORK/panel-submit.log" || {
  log "model_panel_submit reason=$(grep '^REASON ' "$WORK/panel-submit.log" | head -1)"
  fail "the model's second-domain structure was rejected"
}
PANEL_VERSION=""
waited=0
while (( waited < 40 )); do
  PANEL_VERSION="$(panel_structure_version)"
  [[ "$PANEL_VERSION" == "1" ]] && break
  sleep 0.5
  waited=$(( waited + 1 ))
done
[[ "$PANEL_VERSION" == "1" ]] || fail "the model's second-domain structure was never scene-accepted"
panel_pub generated-structure > "$OUT_DIR/panel-structure-after.txt" 2>&1 || true
PANEL_MODEL_KEYS="$(python3 - "$OUT_DIR/panel-generate.txt" <<'PYK'
import re, sys
print(" ".join(m.group(1) for m in (re.match(r"NODE \d+ (\S+) ", l) for l in open(sys.argv[1], encoding="utf-8")) if m))
PYK
)"
for key in ${=PANEL_MODEL_KEYS}; do
  grep -q "NODE [0-9]* $key " "$OUT_DIR/panel-structure-after.txt" \
    || fail "the second-domain accepted structure is missing the model's node $key"
done
# A public field operation through the same client, then an exact read-back.
# The model names the FIELD and the value; the WRITER action, its ARGUMENT name,
# the argument TYPE and the target resource are all resolved from the public
# capability/snapshot text through the typed public client. Nothing here knows
# that the title is written by SET_TITLE or that the target is 8101.
PANEL_WRITE_FIELD="$(awk '/^FIELD /{print $2; exit}' "$PAYLOADS_DIR/panel-write.txt")"
PANEL_WRITE_VALUE="$(sed -n 's/^VALUE //p' "$PAYLOADS_DIR/panel-write.txt" | head -1)"
[[ -n "$PANEL_WRITE_FIELD" && -n "$PANEL_WRITE_VALUE" ]] \
  || fail "panel-write.txt must declare 'FIELD <fieldId>' and 'VALUE <text>'"
python3 - "$export_root/framework/cjgui/shared_operation_core" "$PANEL_DESCRIPTOR" \
  "$PANEL_WRITE_FIELD" "$PANEL_WRITE_VALUE" > "$WORK/panel-title.log" 2>&1 <<'PYWRITE' \
  || fail "the model-initiated second-domain field write failed"
import sys
sys.path.insert(0, sys.argv[1])
from client import SharedOperationArgument
from cjgui_generated_client import GeneratedUiSession
descriptor, field_id, value = sys.argv[2], sys.argv[3], sys.argv[4]
session = GeneratedUiSession.connect(descriptor)
field = session.capabilities().field(field_id)
if field is None or not field.callable or not field.writer:
    print("field is not published as writable:", field_id)
    sys.exit(1)
signature = next((action for action in session.action_signatures() if action.name == field.writer), None)
if signature is None:
    print("the field writer is not a published action:", field.writer)
    sys.exit(1)
candidates = list(signature.parameters)
if len(candidates) > 1:
    preferred = [p for p in candidates if p.name == field.argument]
    candidates = preferred or candidates
if len(candidates) != 1:
    print("cannot pick exactly one writer argument from", [p.name for p in signature.parameters])
    sys.exit(1)
parameter = candidates[0]
if field.editor_kind == "INTEGER" or parameter.value_type == "INTEGER":
    argument = SharedOperationArgument.integer(parameter.name, int(value))
elif field.editor_kind == "BOOLEAN" or parameter.value_type == "BOOLEAN":
    argument = SharedOperationArgument.boolean(parameter.name, value.strip().lower() in ("1", "true"))
else:
    argument = SharedOperationArgument.string(parameter.name, value)
response = session.invoke_action(field.writer, [field.resource_id], [argument])
applied = dict((label, tokens[0]) for label, tokens in response.entries if tokens).get("APPLIED", "false")
print(f"field={field_id} writer={field.writer} argument={parameter.name}:{parameter.value_type} "
      f"target={field.resource_id} applied={applied}")
sys.exit(0 if applied == "true" else 1)
PYWRITE
grep -q 'applied=true' "$WORK/panel-title.log" || fail "the second-domain public field operation was rejected"
[[ "$(panel_field_token "$PANEL_WRITE_FIELD" APPLIED_HEX | hex_to_text)" == "$PANEL_WRITE_VALUE" ]] \
  || fail "the second-domain field read-back mismatch"
log "step4 panel_model_structure_accepted version=$PANEL_VERSION model_write=$(cat "$WORK/panel-title.log" | tr '\n' ' ') readback='$PANEL_WRITE_VALUE' nodes=${PANEL_MODEL_KEYS}"

say "APPLY OK out=$OUT_DIR payloads=$PAYLOADS_DIR desktop_input=$( [[ -n "$BLOCKED_DESKTOP" ]] && print blocked || print verified )"
finish
