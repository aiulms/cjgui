#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 renderer-state mutation request dry-run packet。admitted
# 表示 request shape 可交接，不表示 mutation 可执行。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage126-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-mutation-request-dry-run-first-slice-classifier.packet"
MUTATION_REQUEST_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_MUTATION_REQUEST_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted mutation request classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted mutation request classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$MUTATION_REQUEST_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted mutation request classifier: packet generation failed" >&2
    echo "cjgui semantic-comparison-admitted mutation request classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  MUTATION_REQUEST_PACKET="$(grep -Eo 'semantic_comparison_admitted_mutation_request_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$MUTATION_REQUEST_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted mutation request classifier: provided packet missing $MUTATION_REQUEST_PACKET" >&2
    exit 7
  fi
  echo "provided_mutation_request_packet_used=true" > "$PACKET_LOG"
fi

if [[ -z "$MUTATION_REQUEST_PACKET" || ! -f "$MUTATION_REQUEST_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted mutation request classifier: missing mutation request packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_packet_passed=true"
  "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=true"
  "renderer_state_mutation_request_shape_defined=true"
  "decision_denial_bound_to_mutation_request_rejection=true"
  "mutation_request_non_executable=true"
  "mutation_request_dry_run_only=true"
  "renderer_state_mutation_request_rejected=true"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$MUTATION_REQUEST_PACKET" "$fact"
done

mutation_request_ready="$(fact_value "$MUTATION_REQUEST_PACKET" "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready")"
request_non_exec="$(fact_value "$MUTATION_REQUEST_PACKET" "mutation_request_non_executable")"
request_rejected="$(fact_value "$MUTATION_REQUEST_PACKET" "renderer_state_mutation_request_rejected")"
classifier_route="blocked_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice"
if [[ "$mutation_request_ready" == "true" &&
      "$request_non_exec" == "true" &&
      "$request_rejected" == "true" ]]; then
  classifier_route="admitted_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier_packet_version=1"
  echo "semantic_comparison_admitted_mutation_request_packet=$MUTATION_REQUEST_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier_passed=true"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=$classifier_route"
  echo "semantic_comparison_admitted_renderer_state_mutation_request_dry_run_ready=$mutation_request_ready"
  echo "renderer_state_mutation_request_shape_defined=true"
  echo "decision_inputs_bound_to_mutation_request_shape=true"
  echo "decision_denial_bound_to_mutation_request_rejection=true"
  echo "future_mutation_boundary_bound_to_request_stop_line=true"
  echo "mutation_request_non_executable=$request_non_exec"
  echo "mutation_request_dry_run_only=true"
  echo "renderer_state_mutation_request_rejected=$request_rejected"
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

echo "cjgui semantic-comparison-admitted mutation request classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_mutation_request_dry_run_first_slice_classifier"
echo "cjgui semantic-comparison-admitted mutation request classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic-comparison-admitted mutation request classifier: semantic_comparison_admitted_renderer_state_mutation_request_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic-comparison-admitted mutation request classifier: renderer_state_write=false"
