#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 baseline materialization dry-run packet。缺 baseline
# artifact source 是 fail-closed 工程语义阻断，不是宿主限制。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage123-baseline-materialization-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-materialization-dry-run-first-slice-classifier.packet"
BASELINE_MATERIALIZATION_PACKET="${CJGUI_BASELINE_MATERIALIZATION_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui baseline materialization dry-run classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui baseline materialization dry-run classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui baseline materialization dry-run classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$BASELINE_MATERIALIZATION_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui baseline materialization dry-run classifier: packet generation failed" >&2
    echo "cjgui baseline materialization dry-run classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  BASELINE_MATERIALIZATION_PACKET="$(grep -Eo 'baseline_materialization_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$BASELINE_MATERIALIZATION_PACKET" ]]; then
    echo "cjgui baseline materialization dry-run classifier: provided packet missing $BASELINE_MATERIALIZATION_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_baseline_materialization_packet_used=true"
    echo "baseline_materialization_packet_path=$BASELINE_MATERIALIZATION_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$BASELINE_MATERIALIZATION_PACKET" || ! -f "$BASELINE_MATERIALIZATION_PACKET" ]]; then
  echo "cjgui baseline materialization dry-run classifier: missing baseline materialization packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_packet_passed=true"
  "baseline_materialization_dry_run_ready=true"
  "baseline_materialization_dry_run_only=true"
  "baseline_artifact_source_contract_defined=true"
  "baseline_artifact_freshness_contract_defined=true"
  "baseline_hash_value_redaction_policy_defined=true"
  "missing_baseline_artifact_source_classified=true"
  "baseline_artifact_source_available=false"
  "baseline_artifact_materialized=false"
  "baseline_artifact_freshness_passed=false"
  "baseline_frame_hash_value_redacted=true"
  "baseline_compare_executed=false"
  "semantic_acceptance_admitted=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$BASELINE_MATERIALIZATION_PACKET" "$fact"
done

baseline_materialization_ready="$(fact_value "$BASELINE_MATERIALIZATION_PACKET" "baseline_materialization_dry_run_ready")"
baseline_artifact_materialized="$(fact_value "$BASELINE_MATERIALIZATION_PACKET" "baseline_artifact_materialized")"
baseline_artifact_failure="$(fact_value "$BASELINE_MATERIALIZATION_PACKET" "baseline_artifact_failure_classification")"
renderer_state_allowed="$(fact_value "$BASELINE_MATERIALIZATION_PACKET" "renderer_state_write_after_baseline_materialization_allowed")"
classifier_route="failed_baseline_materialization_dry_run_first_slice"
if [[ "$baseline_materialization_ready" == "true" &&
      "$baseline_artifact_materialized" == "false" &&
      "$baseline_artifact_failure" == "missing_baseline_artifact_source" &&
      "$renderer_state_allowed" == "false" ]]; then
  classifier_route="blocked_baseline_materialization_dry_run_missing_baseline_artifact_source"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_classifier_packet_version=1"
  echo "baseline_materialization_packet=$BASELINE_MATERIALIZATION_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_classifier_passed=true"
  echo "baseline_materialization_dry_run_classifier_route=$classifier_route"
  echo "baseline_materialization_dry_run_ready=$baseline_materialization_ready"
  echo "baseline_materialization_dry_run_only=true"
  echo "baseline_artifact_failure_classification=$baseline_artifact_failure"
  echo "missing_baseline_artifact_source_classified=true"
  echo "baseline_artifact_materialized=$baseline_artifact_materialized"
  echo "baseline_artifact_freshness_passed=false"
  echo "baseline_frame_hash_value_redacted=true"
  echo "baseline_compare_executed=false"
  echo "semantic_acceptance_admitted=false"
  echo "renderer_state_write_after_baseline_materialization_allowed=$renderer_state_allowed"
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

echo "cjgui baseline materialization dry-run classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_classifier"
echo "cjgui baseline materialization dry-run classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui baseline materialization dry-run classifier: baseline_materialization_dry_run_classifier_route=$classifier_route"
echo "cjgui baseline materialization dry-run classifier: renderer_state_write=false"
