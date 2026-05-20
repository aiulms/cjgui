#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 renderer-state write decision result envelope packet。
# admitted 只表示 result envelope 可复用，不表示真实 state mutation。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-write-decision-result-envelope-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-decision-result-envelope-first-slice-classifier.packet"
RESULT_ENVELOPE_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_DECISION_RESULT_ENVELOPE_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write decision result envelope classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write decision result envelope classifier: syntax check failed $PACKET_SCRIPT" >&2
  exit 4
fi

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui semantic-comparison-admitted write decision result envelope classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$RESULT_ENVELOPE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted write decision result envelope classifier: packet generation failed" >&2
    echo "cjgui semantic-comparison-admitted write decision result envelope classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  RESULT_ENVELOPE_PACKET="$(grep -Eo 'semantic_comparison_admitted_write_decision_result_envelope_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$RESULT_ENVELOPE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write decision result envelope classifier: provided packet missing $RESULT_ENVELOPE_PACKET" >&2
    exit 7
  fi
  echo "provided_result_envelope_packet_used=true" > "$PACKET_LOG"
fi

if [[ -z "$RESULT_ENVELOPE_PACKET" || ! -f "$RESULT_ENVELOPE_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted write decision result envelope classifier: missing result envelope packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_packet_passed=true"
  "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=true"
  "renderer_state_write_decision_result_envelope_materialized=true"
  "denial_reason_persisted_as_dry_run_fact=true"
  "future_mutation_boundary_non_executable=true"
  "decision_result_envelope_non_mutating=true"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$RESULT_ENVELOPE_PACKET" "$fact"
done

result_envelope_ready="$(fact_value "$RESULT_ENVELOPE_PACKET" "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready")"
non_mutating="$(fact_value "$RESULT_ENVELOPE_PACKET" "decision_result_envelope_non_mutating")"
future_non_exec="$(fact_value "$RESULT_ENVELOPE_PACKET" "future_mutation_boundary_non_executable")"
classifier_route="blocked_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice"
if [[ "$result_envelope_ready" == "true" &&
      "$non_mutating" == "true" &&
      "$future_non_exec" == "true" ]]; then
  classifier_route="admitted_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_classifier_packet_version=1"
  echo "semantic_comparison_admitted_write_decision_result_envelope_packet=$RESULT_ENVELOPE_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_classifier_passed=true"
  echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_classifier_route=$classifier_route"
  echo "semantic_comparison_admitted_renderer_state_write_decision_result_envelope_ready=$result_envelope_ready"
  echo "renderer_state_write_decision_result_envelope_materialized=true"
  echo "decision_inputs_persisted_as_dry_run_facts=true"
  echo "denial_reason_persisted_as_dry_run_fact=true"
  echo "future_mutation_boundary_persisted_as_dry_run_fact=true"
  echo "future_mutation_boundary_non_executable=$future_non_exec"
  echo "decision_result_envelope_non_mutating=$non_mutating"
  echo "renderer_state_write_decision_denied=true"
  echo "next_mutation_request_probe_input_prepared=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "state_mutation_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
} > "$CLASSIFIER_PACKET"

echo "cjgui semantic-comparison-admitted write decision result envelope classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_result_envelope_first_slice_classifier"
echo "cjgui semantic-comparison-admitted write decision result envelope classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic-comparison-admitted write decision result envelope classifier: semantic_comparison_admitted_renderer_state_write_decision_result_envelope_classifier_route=$classifier_route"
echo "cjgui semantic-comparison-admitted write decision result envelope classifier: renderer_state_write=false"
