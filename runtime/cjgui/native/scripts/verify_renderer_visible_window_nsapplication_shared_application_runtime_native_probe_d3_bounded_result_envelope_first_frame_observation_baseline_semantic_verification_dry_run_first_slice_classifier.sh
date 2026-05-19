#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 baseline / semantic verification dry-run packet。
# admitted 只表示 dry-run verification envelope 可交接，不表示 semantic truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage122-baseline-semantic-verification-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-semantic-verification-dry-run-first-slice-classifier.packet"
BASELINE_SEMANTIC_PACKET="${CJGUI_BASELINE_SEMANTIC_VERIFICATION_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer baseline semantic verification dry-run classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer baseline semantic verification dry-run classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer baseline semantic verification dry-run classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$BASELINE_SEMANTIC_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer baseline semantic verification dry-run classifier: packet generation failed" >&2
    echo "cjgui renderer baseline semantic verification dry-run classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  BASELINE_SEMANTIC_PACKET="$(grep -Eo 'baseline_semantic_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$BASELINE_SEMANTIC_PACKET" ]]; then
    echo "cjgui renderer baseline semantic verification dry-run classifier: provided packet missing $BASELINE_SEMANTIC_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_baseline_semantic_packet_used=true"
    echo "baseline_semantic_packet_path=$BASELINE_SEMANTIC_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$BASELINE_SEMANTIC_PACKET" || ! -f "$BASELINE_SEMANTIC_PACKET" ]]; then
  echo "cjgui renderer baseline semantic verification dry-run classifier: missing baseline semantic packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_packet_passed=true"
  "baseline_semantic_verification_dry_run_ready=true"
  "baseline_comparison_input_contract_defined=true"
  "baseline_compare_gate_defined=true"
  "semantic_acceptance_fields_defined=true"
  "missing_baseline_classified_as_pending_dry_run=true"
  "frame_hash_summary_only=true"
  "frame_hash_value_persisted=false"
  "baseline_compared=false"
  "semantic_acceptance_dry_run_only=true"
  "semantic_acceptance_admitted=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$BASELINE_SEMANTIC_PACKET" "$fact"
done

baseline_ready="$(fact_value "$BASELINE_SEMANTIC_PACKET" "baseline_semantic_verification_dry_run_ready")"
missing_baseline_pending="$(fact_value "$BASELINE_SEMANTIC_PACKET" "missing_baseline_classified_as_pending_dry_run")"
semantic_acceptance="$(fact_value "$BASELINE_SEMANTIC_PACKET" "semantic_acceptance_admitted")"
classifier_route="blocked_baseline_semantic_verification_dry_run_first_slice"
if [[ "$baseline_ready" == "true" &&
      "$missing_baseline_pending" == "true" &&
      "$semantic_acceptance" == "false" ]]; then
  classifier_route="admitted_baseline_semantic_verification_dry_run_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_classifier_packet_version=1"
  echo "baseline_semantic_packet=$BASELINE_SEMANTIC_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_classifier_passed=true"
  echo "baseline_semantic_verification_dry_run_classifier_route=$classifier_route"
  echo "baseline_semantic_verification_dry_run_ready=$baseline_ready"
  echo "baseline_comparison_input_contract_defined=true"
  echo "baseline_compare_gate_defined=true"
  echo "semantic_acceptance_fields_defined=true"
  echo "missing_baseline_classified_as_pending_dry_run=$missing_baseline_pending"
  echo "frame_hash_summary_only=true"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_match=false"
  echo "semantic_acceptance_dry_run_only=true"
  echo "semantic_acceptance_admitted=$semantic_acceptance"
  echo "state_write_after_semantic_verification_allowed=false"
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

echo "cjgui renderer baseline semantic verification dry-run classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_semantic_verification_dry_run_first_slice_classifier"
echo "cjgui renderer baseline semantic verification dry-run classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer baseline semantic verification dry-run classifier: baseline_semantic_verification_dry_run_classifier_route=$classifier_route"
echo "cjgui renderer baseline semantic verification dry-run classifier: renderer_state_write=false"
