#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 renderer-state write decision dry-run packet。admitted
# 只表示 decision 可交接给 result envelope，不表示真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-write-decision-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-decision-dry-run-first-slice-classifier.packet"
WRITE_DECISION_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_DECISION_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write decision classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write decision classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted write decision classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$WRITE_DECISION_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted write decision classifier: packet generation failed" >&2
    echo "cjgui semantic-comparison-admitted write decision classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  WRITE_DECISION_PACKET="$(grep -Eo 'semantic_comparison_admitted_write_decision_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$WRITE_DECISION_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write decision classifier: provided packet missing $WRITE_DECISION_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_write_decision_packet_used=true"
    echo "semantic_comparison_admitted_write_decision_packet_path=$WRITE_DECISION_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$WRITE_DECISION_PACKET" || ! -f "$WRITE_DECISION_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted write decision classifier: missing write decision packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_packet_passed=true"
  "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=true"
  "renderer_state_write_decision_dry_run_only=true"
  "renderer_state_write_decision_input_fields_defined=true"
  "renderer_state_write_denial_reasons_defined=true"
  "future_mutation_boundary_defined=true"
  "renderer_state_write_decision_denied=true"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$WRITE_DECISION_PACKET" "$fact"
done

write_decision_ready="$(fact_value "$WRITE_DECISION_PACKET" "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready")"
dry_run_only="$(fact_value "$WRITE_DECISION_PACKET" "renderer_state_write_decision_dry_run_only")"
decision_denied="$(fact_value "$WRITE_DECISION_PACKET" "renderer_state_write_decision_denied")"
future_boundary="$(fact_value "$WRITE_DECISION_PACKET" "future_mutation_boundary_defined")"
classifier_route="blocked_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice"
if [[ "$write_decision_ready" == "true" &&
      "$dry_run_only" == "true" &&
      "$decision_denied" == "true" &&
      "$future_boundary" == "true" ]]; then
  classifier_route="admitted_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_classifier_packet_version=1"
  echo "semantic_comparison_admitted_write_decision_packet=$WRITE_DECISION_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_classifier_passed=true"
  echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_classifier_route=$classifier_route"
  echo "semantic_comparison_admitted_renderer_state_write_decision_dry_run_ready=$write_decision_ready"
  echo "renderer_state_write_decision_dry_run_only=$dry_run_only"
  echo "renderer_state_write_decision_input_fields_defined=true"
  echo "renderer_state_write_denial_reasons_defined=true"
  echo "future_mutation_boundary_defined=$future_boundary"
  echo "renderer_state_write_decision_denied=$decision_denied"
  echo "renderer_state_write_after_decision_allowed=false"
  echo "future_mutation_boundary_executable=false"
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

echo "cjgui semantic-comparison-admitted write decision classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_decision_dry_run_first_slice_classifier"
echo "cjgui semantic-comparison-admitted write decision classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic-comparison-admitted write decision classifier: semantic_comparison_admitted_renderer_state_write_decision_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic-comparison-admitted write decision classifier: renderer_state_write=false"
