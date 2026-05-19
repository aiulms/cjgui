#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 baseline artifact positive fixture dry-run packet。
# admitted route 只说明 redacted fixture 输入可进入 comparison dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage124-baseline-artifact-positive-fixture-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-artifact-positive-fixture-dry-run-first-slice-classifier.packet"
BASELINE_FIXTURE_PACKET="${CJGUI_BASELINE_ARTIFACT_POSITIVE_FIXTURE_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui baseline artifact positive fixture dry-run classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui baseline artifact positive fixture dry-run classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui baseline artifact positive fixture dry-run classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$BASELINE_FIXTURE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui baseline artifact positive fixture dry-run classifier: packet generation failed" >&2
    echo "cjgui baseline artifact positive fixture dry-run classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  BASELINE_FIXTURE_PACKET="$(grep -Eo 'baseline_fixture_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$BASELINE_FIXTURE_PACKET" ]]; then
    echo "cjgui baseline artifact positive fixture dry-run classifier: provided packet missing $BASELINE_FIXTURE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_baseline_fixture_packet_used=true"
    echo "baseline_fixture_packet_path=$BASELINE_FIXTURE_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$BASELINE_FIXTURE_PACKET" || ! -f "$BASELINE_FIXTURE_PACKET" ]]; then
  echo "cjgui baseline artifact positive fixture dry-run classifier: missing baseline fixture packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_packet_passed=true"
  "baseline_artifact_positive_fixture_dry_run_ready=true"
  "baseline_artifact_positive_fixture_dry_run_only=true"
  "baseline_artifact_fixture_materialized=true"
  "baseline_artifact_fixture_freshness_passed=true"
  "baseline_fixture_frame_hash_value_redacted=true"
  "baseline_compare_input_shape_defined=true"
  "baseline_compare_executed=false"
  "renderer_state_write_after_baseline_fixture_allowed=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$BASELINE_FIXTURE_PACKET" "$fact"
done

baseline_fixture_ready="$(fact_value "$BASELINE_FIXTURE_PACKET" "baseline_artifact_positive_fixture_dry_run_ready")"
fixture_materialized="$(fact_value "$BASELINE_FIXTURE_PACKET" "baseline_artifact_fixture_materialized")"
fixture_fresh="$(fact_value "$BASELINE_FIXTURE_PACKET" "baseline_artifact_fixture_freshness_passed")"
hash_redacted="$(fact_value "$BASELINE_FIXTURE_PACKET" "baseline_fixture_frame_hash_value_redacted")"
renderer_state_allowed="$(fact_value "$BASELINE_FIXTURE_PACKET" "renderer_state_write_after_baseline_fixture_allowed")"
classifier_route="failed_baseline_artifact_positive_fixture_dry_run_first_slice"
if [[ "$baseline_fixture_ready" == "true" &&
      "$fixture_materialized" == "true" &&
      "$fixture_fresh" == "true" &&
      "$hash_redacted" == "true" &&
      "$renderer_state_allowed" == "false" ]]; then
  classifier_route="admitted_baseline_artifact_positive_fixture_dry_run_first_slice"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_classifier_packet_version=1"
  echo "baseline_fixture_packet=$BASELINE_FIXTURE_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_classifier_passed=true"
  echo "baseline_artifact_positive_fixture_dry_run_classifier_route=$classifier_route"
  echo "baseline_artifact_positive_fixture_dry_run_ready=$baseline_fixture_ready"
  echo "baseline_artifact_positive_fixture_dry_run_only=true"
  echo "baseline_artifact_fixture_materialized=$fixture_materialized"
  echo "baseline_artifact_fixture_freshness_passed=$fixture_fresh"
  echo "baseline_fixture_frame_hash_value_redacted=$hash_redacted"
  echo "baseline_compare_input_shape_defined=true"
  echo "semantic_comparison_ready_to_dry_run=true"
  echo "renderer_state_write_after_baseline_fixture_allowed=$renderer_state_allowed"
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

echo "cjgui baseline artifact positive fixture dry-run classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_artifact_positive_fixture_dry_run_first_slice_classifier"
echo "cjgui baseline artifact positive fixture dry-run classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui baseline artifact positive fixture dry-run classifier: baseline_artifact_positive_fixture_dry_run_classifier_route=$classifier_route"
echo "cjgui baseline artifact positive fixture dry-run classifier: renderer_state_write=false"
