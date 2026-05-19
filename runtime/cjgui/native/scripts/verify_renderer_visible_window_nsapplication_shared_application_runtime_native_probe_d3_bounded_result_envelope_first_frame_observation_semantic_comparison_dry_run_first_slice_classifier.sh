#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 semantic comparison dry-run packet。positive fixture
# admitted 仍是 dry-run truth，不允许 renderer/runtime state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage124-semantic-comparison-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-dry-run-first-slice-classifier.packet"
SEMANTIC_COMPARISON_PACKET="${CJGUI_SEMANTIC_COMPARISON_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic comparison dry-run classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic comparison dry-run classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui semantic comparison dry-run classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$SEMANTIC_COMPARISON_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic comparison dry-run classifier: packet generation failed" >&2
    echo "cjgui semantic comparison dry-run classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  SEMANTIC_COMPARISON_PACKET="$(grep -Eo 'semantic_comparison_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$SEMANTIC_COMPARISON_PACKET" ]]; then
    echo "cjgui semantic comparison dry-run classifier: provided packet missing $SEMANTIC_COMPARISON_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_semantic_comparison_packet_used=true"
    echo "semantic_comparison_packet_path=$SEMANTIC_COMPARISON_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$SEMANTIC_COMPARISON_PACKET" || ! -f "$SEMANTIC_COMPARISON_PACKET" ]]; then
  echo "cjgui semantic comparison dry-run classifier: missing semantic comparison packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_packet_passed=true"
  "semantic_comparison_dry_run_ready=true"
  "semantic_comparison_dry_run_only=true"
  "semantic_comparison_evaluated=true"
  "semantic_comparison_positive_fixture_matched=true"
  "semantic_comparison_negative_fixture_rejected=true"
  "semantic_acceptance_comparison_admitted=true"
  "semantic_acceptance_failure_classification=none"
  "renderer_state_write_after_semantic_comparison_allowed=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$SEMANTIC_COMPARISON_PACKET" "$fact"
done

semantic_comparison_ready="$(fact_value "$SEMANTIC_COMPARISON_PACKET" "semantic_comparison_dry_run_ready")"
semantic_acceptance_admitted="$(fact_value "$SEMANTIC_COMPARISON_PACKET" "semantic_acceptance_comparison_admitted")"
positive_match="$(fact_value "$SEMANTIC_COMPARISON_PACKET" "semantic_comparison_positive_fixture_matched")"
renderer_state_allowed="$(fact_value "$SEMANTIC_COMPARISON_PACKET" "renderer_state_write_after_semantic_comparison_allowed")"
classifier_route="failed_semantic_comparison_dry_run_first_slice"
if [[ "$semantic_comparison_ready" == "true" &&
      "$semantic_acceptance_admitted" == "true" &&
      "$positive_match" == "true" &&
      "$renderer_state_allowed" == "false" ]]; then
  classifier_route="admitted_semantic_comparison_dry_run_positive_fixture"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_classifier_packet_version=1"
  echo "semantic_comparison_packet=$SEMANTIC_COMPARISON_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_classifier_passed=true"
  echo "semantic_comparison_dry_run_classifier_route=$classifier_route"
  echo "semantic_comparison_dry_run_ready=$semantic_comparison_ready"
  echo "semantic_comparison_dry_run_only=true"
  echo "semantic_comparison_evaluated=true"
  echo "semantic_comparison_positive_fixture_matched=$positive_match"
  echo "semantic_comparison_negative_fixture_rejected=true"
  echo "semantic_acceptance_comparison_admitted=$semantic_acceptance_admitted"
  echo "semantic_acceptance_failure_classification=none"
  echo "renderer_state_write_after_semantic_comparison_allowed=$renderer_state_allowed"
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

echo "cjgui semantic comparison dry-run classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_classifier"
echo "cjgui semantic comparison dry-run classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic comparison dry-run classifier: semantic_comparison_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic comparison dry-run classifier: renderer_state_write=false"
