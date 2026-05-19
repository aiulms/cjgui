#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 semantic acceptance result dry-run packet。blocked
# route 是期望结果：missing baseline artifact 不能进入 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage123-semantic-acceptance-result-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-acceptance-result-dry-run-first-slice-classifier.packet"
SEMANTIC_ACCEPTANCE_PACKET="${CJGUI_SEMANTIC_ACCEPTANCE_RESULT_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic acceptance result dry-run classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic acceptance result dry-run classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui semantic acceptance result dry-run classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$SEMANTIC_ACCEPTANCE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic acceptance result dry-run classifier: packet generation failed" >&2
    echo "cjgui semantic acceptance result dry-run classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  SEMANTIC_ACCEPTANCE_PACKET="$(grep -Eo 'semantic_acceptance_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$SEMANTIC_ACCEPTANCE_PACKET" ]]; then
    echo "cjgui semantic acceptance result dry-run classifier: provided packet missing $SEMANTIC_ACCEPTANCE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_semantic_acceptance_packet_used=true"
    echo "semantic_acceptance_packet_path=$SEMANTIC_ACCEPTANCE_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$SEMANTIC_ACCEPTANCE_PACKET" || ! -f "$SEMANTIC_ACCEPTANCE_PACKET" ]]; then
  echo "cjgui semantic acceptance result dry-run classifier: missing semantic acceptance packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_packet_passed=true"
  "semantic_acceptance_result_dry_run_ready=true"
  "semantic_acceptance_result_dry_run_only=true"
  "semantic_acceptance_result_envelope_defined=true"
  "semantic_acceptance_failure_classification_defined=true"
  "missing_baseline_artifact_blocks_semantic_acceptance=true"
  "semantic_acceptance_failure_classification=missing_baseline_artifact_source"
  "semantic_acceptance_evaluated=false"
  "semantic_acceptance_admitted=false"
  "renderer_state_write_after_semantic_acceptance_result_allowed=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$SEMANTIC_ACCEPTANCE_PACKET" "$fact"
done

semantic_acceptance_ready="$(fact_value "$SEMANTIC_ACCEPTANCE_PACKET" "semantic_acceptance_result_dry_run_ready")"
semantic_acceptance_admitted="$(fact_value "$SEMANTIC_ACCEPTANCE_PACKET" "semantic_acceptance_admitted")"
semantic_acceptance_failure="$(fact_value "$SEMANTIC_ACCEPTANCE_PACKET" "semantic_acceptance_failure_classification")"
renderer_state_allowed="$(fact_value "$SEMANTIC_ACCEPTANCE_PACKET" "renderer_state_write_after_semantic_acceptance_result_allowed")"
classifier_route="failed_semantic_acceptance_result_dry_run_first_slice"
if [[ "$semantic_acceptance_ready" == "true" &&
      "$semantic_acceptance_admitted" == "false" &&
      "$semantic_acceptance_failure" == "missing_baseline_artifact_source" &&
      "$renderer_state_allowed" == "false" ]]; then
  classifier_route="blocked_semantic_acceptance_result_dry_run_missing_baseline_artifact_source"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_classifier_packet_version=1"
  echo "semantic_acceptance_packet=$SEMANTIC_ACCEPTANCE_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_classifier_passed=true"
  echo "semantic_acceptance_result_dry_run_classifier_route=$classifier_route"
  echo "semantic_acceptance_result_dry_run_ready=$semantic_acceptance_ready"
  echo "semantic_acceptance_result_dry_run_only=true"
  echo "semantic_acceptance_failure_classification=$semantic_acceptance_failure"
  echo "missing_baseline_artifact_blocks_semantic_acceptance=true"
  echo "semantic_acceptance_evaluated=false"
  echo "semantic_acceptance_admitted=$semantic_acceptance_admitted"
  echo "renderer_state_write_after_semantic_acceptance_result_allowed=$renderer_state_allowed"
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

echo "cjgui semantic acceptance result dry-run classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_classifier"
echo "cjgui semantic acceptance result dry-run classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic acceptance result dry-run classifier: semantic_acceptance_result_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic acceptance result dry-run classifier: renderer_state_write=false"
