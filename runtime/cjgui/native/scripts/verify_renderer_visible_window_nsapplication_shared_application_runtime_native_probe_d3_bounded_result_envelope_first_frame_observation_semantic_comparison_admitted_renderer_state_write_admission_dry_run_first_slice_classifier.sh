#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 semantic-comparison-admitted renderer-state write
# admission dry-run packet。admitted 只表示 non-mutating dry-run 可进入
# state-update envelope，不表示真实写入许可。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage125-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice-classifier.packet"
WRITE_ADMISSION_PACKET="${CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_WRITE_ADMISSION_DRY_RUN_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write admission classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write admission classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted write admission classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$WRITE_ADMISSION_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui semantic-comparison-admitted write admission classifier: packet generation failed" >&2
    echo "cjgui semantic-comparison-admitted write admission classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  WRITE_ADMISSION_PACKET="$(grep -Eo 'semantic_comparison_admitted_write_admission_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$WRITE_ADMISSION_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write admission classifier: provided packet missing $WRITE_ADMISSION_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_write_admission_packet_used=true"
    echo "semantic_comparison_admitted_write_admission_packet_path=$WRITE_ADMISSION_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$WRITE_ADMISSION_PACKET" || ! -f "$WRITE_ADMISSION_PACKET" ]]; then
  echo "cjgui semantic-comparison-admitted write admission classifier: missing write admission packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_packet_passed=true"
  "semantic_comparison_dry_run_ready=true"
  "semantic_acceptance_comparison_admitted=true"
  "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=true"
  "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=true"
  "state_mutation_request_admission_fields_defined=true"
  "visibility_publication_admission_fields_defined=true"
  "rollback_fallback_admission_fields_defined=true"
  "state_mutation_request_allowed=false"
  "visibility_publication_allowed=false"
  "rollback_state_write_allowed=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$WRITE_ADMISSION_PACKET" "$fact"
done

write_admission_ready="$(fact_value "$WRITE_ADMISSION_PACKET" "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready")"
non_mutating="$(fact_value "$WRITE_ADMISSION_PACKET" "semantic_comparison_admitted_renderer_state_write_admission_non_mutating")"
state_fields="$(fact_value "$WRITE_ADMISSION_PACKET" "state_mutation_request_admission_fields_defined")"
visibility_fields="$(fact_value "$WRITE_ADMISSION_PACKET" "visibility_publication_admission_fields_defined")"
rollback_fields="$(fact_value "$WRITE_ADMISSION_PACKET" "rollback_fallback_admission_fields_defined")"
classifier_route="blocked_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice"
if [[ "$write_admission_ready" == "true" &&
      "$non_mutating" == "true" &&
      "$state_fields" == "true" &&
      "$visibility_fields" == "true" &&
      "$rollback_fields" == "true" ]]; then
  classifier_route="admitted_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_classifier_packet_version=1"
  echo "semantic_comparison_admitted_write_admission_packet=$WRITE_ADMISSION_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_classifier_passed=true"
  echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_classifier_route=$classifier_route"
  echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=$write_admission_ready"
  echo "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=$non_mutating"
  echo "state_mutation_request_admission_fields_defined=$state_fields"
  echo "visibility_publication_admission_fields_defined=$visibility_fields"
  echo "rollback_fallback_admission_fields_defined=$rollback_fields"
  echo "state_mutation_request_allowed=false"
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

echo "cjgui semantic-comparison-admitted write admission classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_classifier"
echo "cjgui semantic-comparison-admitted write admission classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui semantic-comparison-admitted write admission classifier: semantic_comparison_admitted_renderer_state_write_admission_dry_run_classifier_route=$classifier_route"
echo "cjgui semantic-comparison-admitted write admission classifier: renderer_state_write=false"
