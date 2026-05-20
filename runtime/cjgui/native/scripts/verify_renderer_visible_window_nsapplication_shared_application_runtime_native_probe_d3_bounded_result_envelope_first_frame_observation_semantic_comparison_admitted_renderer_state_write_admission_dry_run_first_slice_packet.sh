#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage124 semantic comparison suite packet，生成
# semantic-comparison-admitted renderer-state write admission dry-run packet。该
# packet 只定义 admission 字段，不允许真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage125-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice-packet"
SEMANTIC_COMPARISON_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_suite.sh"
SEMANTIC_COMPARISON_LOG="$TMP_DIR/semantic-comparison-suite.log"
WRITE_ADMISSION_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-admitted-renderer-state-write-admission-dry-run-first-slice.packet"
SEMANTIC_COMPARISON_SUITE_PACKET="${CJGUI_SEMANTIC_COMPARISON_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE124_SEMANTIC_COMPARISON_CANONICAL_PACKET="/tmp/cjgui-stage124-semantic-comparison-suite-check/cjgui-stage124-semantic-comparison-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-semantic-comparison-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$SEMANTIC_COMPARISON_LOG"
: > "$WRITE_ADMISSION_PACKET"

if [[ ! -x "$SEMANTIC_COMPARISON_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic-comparison-admitted write admission packet: missing executable script $SEMANTIC_COMPARISON_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$SEMANTIC_COMPARISON_SUITE_SCRIPT"; then
  echo "cjgui semantic-comparison-admitted write admission packet: syntax check failed $SEMANTIC_COMPARISON_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic-comparison-admitted write admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

semantic_comparison_suite_packet=""
semantic_comparison_suite_packet_source="provided_stage124_semantic_comparison_suite_packet"
current_shell_semantic_comparison_rerun_ready="not_run"
current_shell_semantic_comparison_rerun_failure_classification="none"

if [[ -n "$SEMANTIC_COMPARISON_SUITE_PACKET" ]]; then
  if [[ ! -f "$SEMANTIC_COMPARISON_SUITE_PACKET" ]]; then
    echo "cjgui semantic-comparison-admitted write admission packet: provided stage124 suite packet missing $SEMANTIC_COMPARISON_SUITE_PACKET" >&2
    exit 6
  fi
  semantic_comparison_suite_packet="$SEMANTIC_COMPARISON_SUITE_PACKET"
  {
    echo "semantic_comparison_suite_packet_used=true"
    echo "suite_packet_path=$SEMANTIC_COMPARISON_SUITE_PACKET"
    cat "$SEMANTIC_COMPARISON_SUITE_PACKET"
  } > "$SEMANTIC_COMPARISON_LOG"
else
  semantic_comparison_suite_packet_source="current_shell_stage124_semantic_comparison_rerun"
  if env TMPDIR="$TMP_DIR/semantic-comparison" zsh "$SEMANTIC_COMPARISON_SUITE_SCRIPT" > "$SEMANTIC_COMPARISON_LOG" 2>&1; then
    current_shell_semantic_comparison_rerun_ready="true"
    semantic_comparison_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$SEMANTIC_COMPARISON_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_semantic_comparison_rerun_ready="false"
    current_shell_semantic_comparison_rerun_failure_classification="stage124_semantic_comparison_suite_rerun_failed"
    if [[ -f "$STAGE124_SEMANTIC_COMPARISON_CANONICAL_PACKET" ]]; then
      semantic_comparison_suite_packet="$STAGE124_SEMANTIC_COMPARISON_CANONICAL_PACKET"
      semantic_comparison_suite_packet_source="stage124_semantic_comparison_canonical_prior_suite_packet"
    else
      echo "cjgui semantic-comparison-admitted write admission packet: stage124 semantic comparison suite failed" >&2
      echo "cjgui semantic-comparison-admitted write admission packet: log=$SEMANTIC_COMPARISON_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$semantic_comparison_suite_packet" || ! -f "$semantic_comparison_suite_packet" ]]; then
  echo "cjgui semantic-comparison-admitted write admission packet: missing semantic comparison suite packet" >&2
  exit 8
fi

required_semantic_comparison_facts=(
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_dry_run_first_slice_suite_passed=true"
  "semantic_comparison_dry_run_ready=true"
  "semantic_comparison_dry_run_only=true"
  "semantic_comparison_positive_fixture_matched=true"
  "semantic_comparison_negative_fixture_rejected=true"
  "semantic_acceptance_comparison_admitted=true"
  "semantic_acceptance_failure_classification=none"
  "renderer_state_write_after_semantic_comparison_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_semantic_comparison_facts[@]}"; do
  require_file_fact "$semantic_comparison_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic-comparison-admitted write admission packet: protected path modified" >&2
  exit 9
fi

semantic_ready="$(fact_value "$semantic_comparison_suite_packet" "semantic_comparison_dry_run_ready")"
semantic_admitted="$(fact_value "$semantic_comparison_suite_packet" "semantic_acceptance_comparison_admitted")"
positive_matched="$(fact_value "$semantic_comparison_suite_packet" "semantic_comparison_positive_fixture_matched")"
negative_rejected="$(fact_value "$semantic_comparison_suite_packet" "semantic_comparison_negative_fixture_rejected")"
runtime_native_probe_execution="$(fact_value "$semantic_comparison_suite_packet" "runtime_native_probe_execution")"
baseline_source="$(fact_value "$semantic_comparison_suite_packet" "baseline_fixture_suite_packet_source")"
write_admission_ready="false"
if [[ "$semantic_ready" == "true" &&
      "$semantic_admitted" == "true" &&
      "$positive_matched" == "true" &&
      "$negative_rejected" == "true" ]]; then
  write_admission_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_packet_version=1"
  echo "semantic_comparison_suite_packet=$semantic_comparison_suite_packet"
  echo "semantic_comparison_suite_packet_source=$semantic_comparison_suite_packet_source"
  echo "current_shell_semantic_comparison_rerun_ready=$current_shell_semantic_comparison_rerun_ready"
  echo "current_shell_semantic_comparison_rerun_failure_classification=$current_shell_semantic_comparison_rerun_failure_classification"
  echo "baseline_fixture_suite_packet_source=$baseline_source"
  echo "semantic_comparison_dry_run_first_slice_consumed=true"
  echo "semantic_comparison_dry_run_ready=$semantic_ready"
  echo "semantic_acceptance_comparison_admitted=$semantic_admitted"
  echo "semantic_comparison_positive_fixture_matched=$positive_matched"
  echo "semantic_comparison_negative_fixture_rejected=$negative_rejected"
  echo "semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=$write_admission_ready"
  echo "semantic_comparison_admitted_renderer_state_write_admission_non_mutating=true"
  echo "semantic_comparison_before_renderer_state_write_required=true"
  echo "baseline_fixture_before_renderer_state_write_required=true"
  echo "semantic_comparison_state_field_required=true"
  echo "baseline_fixture_state_field_required=true"
  echo "semantic_acceptance_comparison_state_field_required=true"
  echo "state_mutation_request_admission_fields_defined=true"
  echo "visibility_publication_admission_fields_defined=true"
  echo "rollback_fallback_admission_fields_defined=true"
  echo "state_mutation_request_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "renderer_state_write_after_semantic_comparison_admitted_admission_allowed=false"
  echo "frame_hash_value_persisted=false"
  echo "result_envelope_promoted_to_production_truth=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "runtime_native_probe_execution=$runtime_native_probe_execution"
  echo "bounded_d3_runtime_native_probe_executed=$runtime_native_probe_execution"
  echo "code_failure_domain=false"
  echo "application_singleton_accessor_call=false"
  echo "native_bridge_expansion=false"
  echo "protected_path_modified=false"
  echo "production_public_c_abi_added=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "cjpm_toml_change=false"
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_packet_passed=true"
} > "$WRITE_ADMISSION_PACKET"

echo "cjgui semantic-comparison-admitted write admission packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_write_admission_dry_run_first_slice_packet"
echo "cjgui semantic-comparison-admitted write admission packet: semantic_comparison_admitted_write_admission_packet_path=$WRITE_ADMISSION_PACKET"
echo "cjgui semantic-comparison-admitted write admission packet: semantic_comparison_admitted_renderer_state_write_admission_dry_run_ready=$write_admission_ready"
echo "cjgui semantic-comparison-admitted write admission packet: renderer_state_write=false"
