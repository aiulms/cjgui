#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage104 join packet。join preflight ready 只表示
# admitted bounded envelope 与 independent write-decision contract 已绑定；
# renderer-state write 仍由后续 production write admission 决定。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-d3-bounded-result-envelope-renderer-state-write-decision-join-classifier"
JOIN_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_renderer_state_write_decision_join_packet.sh"
JOIN_LOG="$TMP_DIR/d3-bounded-result-envelope-renderer-state-write-decision-join.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-renderer-state-write-decision-join-classifier.packet"
JOIN_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_RENDERER_STATE_WRITE_DECISION_JOIN_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$JOIN_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$JOIN_PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: missing executable script $JOIN_PACKET_SCRIPT" >&2
  exit 3
fi

if [[ -n "$JOIN_PACKET" ]]; then
  if [[ ! -f "$JOIN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: join packet missing $JOIN_PACKET" >&2
    exit 4
  fi
  {
    echo "join_packet_used=true"
    echo "join_packet_path=$JOIN_PACKET"
    cat "$JOIN_PACKET"
  } > "$JOIN_LOG"
else
  if ! env TMPDIR="$TMP_DIR/join" zsh "$JOIN_PACKET_SCRIPT" > "$JOIN_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: join packet failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: log=$JOIN_LOG" >&2
    exit 5
  fi
fi

join_packet="${JOIN_PACKET:-$(grep -Eo 'join_packet_path=[^[:space:]]+' "$JOIN_LOG" | tail -1 | cut -d= -f2-)}"
if [[ -z "$join_packet" || ! -f "$join_packet" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: missing join packet" >&2
  exit 6
fi

required_join_facts=(
  "d3_bounded_result_envelope_renderer_state_write_decision_join_packet_passed=true"
  "bounded_admission_input_consumed=true"
  "independent_write_decision_contract_consumed=true"
  "renderer_state_write_decision_contract_ready=true"
  "write_decision_contract_is_independent=true"
  "write_decision_contract_is_not_write_permission=true"
  "production_write_admission_after_join_preflight_required=true"
  "renderer_state_write_after_join_preflight_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
)
for fact in "${required_join_facts[@]}"; do
  if ! grep -F "$fact" "$join_packet" >/dev/null 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: missing join fact $fact" >&2
    exit 7
  fi
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: protected path modified" >&2
  exit 8
fi

guarded_join_preflight_ready="$(grep -Eo '^guarded_write_decision_join_preflight_ready=(true|false)' "$join_packet" | tail -1 | cut -d= -f2)"
bounded_admission_input_missing="$(grep -Eo '^bounded_admission_input_missing=(true|false)' "$join_packet" | tail -1 | cut -d= -f2)"
admitted_fixture_input_used="$(grep -Eo '^admitted_fixture_input_used=(true|false)' "$join_packet" | tail -1 | cut -d= -f2)"
runtime_native_probe_execution="$(grep -Eo '^runtime_native_probe_execution=(true|false)' "$join_packet" | tail -1 | cut -d= -f2)"

{
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_classifier_packet_version=1"
  echo "join_packet=$join_packet"
  echo "d3_bounded_result_envelope_renderer_state_write_decision_join_classifier_passed=true"
  echo "guarded_write_decision_join_preflight_ready=$guarded_join_preflight_ready"
  echo "bounded_admission_input_missing=$bounded_admission_input_missing"
  echo "admitted_fixture_input_used=$admitted_fixture_input_used"
  echo "write_decision_contract_is_independent=true"
  echo "write_decision_contract_is_not_write_permission=true"
  echo "join_preflight_is_not_renderer_state_write_permission=true"
  echo "production_write_admission_after_join_preflight_required=true"
  echo "renderer_state_write_after_join_preflight_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "backend_ready_truth=false"
  echo "code_failure_domain=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: route_classification=d3_bounded_result_envelope_renderer_state_write_decision_join_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: guarded_write_decision_join_preflight_ready=$guarded_join_preflight_ready"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: bounded_admission_input_missing=$bounded_admission_input_missing"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: renderer_state_write_after_join_preflight_allowed=false"
echo "cjgui renderer NSApplication runtime native probe D3 bounded result envelope renderer state write decision join classifier: renderer_state_write=false"
