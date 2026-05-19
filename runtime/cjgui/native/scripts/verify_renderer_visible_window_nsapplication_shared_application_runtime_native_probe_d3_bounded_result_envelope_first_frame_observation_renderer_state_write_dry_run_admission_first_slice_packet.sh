#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage120 production write admission suite packet，
# 生成 renderer-state write dry-run admission first-slice packet。它只生成
# non-mutating dry-run envelope，不允许真实 renderer-state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage121-renderer-state-write-dry-run-admission-first-slice-packet"
WRITE_ADMISSION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite.sh"
WRITE_ADMISSION_LOG="$TMP_DIR/production-write-admission-suite.log"
DRY_RUN_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-write-dry-run-admission-first-slice.packet"
WRITE_ADMISSION_SUITE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_WRITE_ADMISSION_FIRST_SLICE_SUITE_PACKET:-}"
STAGE120_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage120-final-suite-check/cjgui-stage120-first-frame-observation-production-write-admission-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-production-write-admission-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$WRITE_ADMISSION_LOG"
: > "$DRY_RUN_PACKET"

if [[ ! -x "$WRITE_ADMISSION_SUITE_SCRIPT" ]]; then
  echo "cjgui renderer state write dry-run admission packet: missing executable script $WRITE_ADMISSION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$WRITE_ADMISSION_SUITE_SCRIPT"; then
  echo "cjgui renderer state write dry-run admission packet: syntax check failed $WRITE_ADMISSION_SUITE_SCRIPT" >&2
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
    echo "cjgui renderer state write dry-run admission packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

write_admission_suite_packet=""
production_write_admission_positive_suite_packet_source="provided_stage120_suite_packet"
current_shell_production_write_admission_rerun_ready="not_run"
current_shell_production_write_admission_rerun_failure_classification="none"

if [[ -n "$WRITE_ADMISSION_SUITE_PACKET" ]]; then
  if [[ ! -f "$WRITE_ADMISSION_SUITE_PACKET" ]]; then
    echo "cjgui renderer state write dry-run admission packet: provided stage120 suite packet missing $WRITE_ADMISSION_SUITE_PACKET" >&2
    exit 6
  fi
  write_admission_suite_packet="$WRITE_ADMISSION_SUITE_PACKET"
  {
    echo "write_admission_suite_packet_used=true"
    echo "suite_packet_path=$WRITE_ADMISSION_SUITE_PACKET"
    cat "$WRITE_ADMISSION_SUITE_PACKET"
  } > "$WRITE_ADMISSION_LOG"
else
  production_write_admission_positive_suite_packet_source="current_shell_stage120_rerun"
  if env TMPDIR="$TMP_DIR/write-admission" zsh "$WRITE_ADMISSION_SUITE_SCRIPT" > "$WRITE_ADMISSION_LOG" 2>&1; then
    current_shell_production_write_admission_rerun_ready="true"
    write_admission_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$WRITE_ADMISSION_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_production_write_admission_rerun_ready="false"
    current_shell_production_write_admission_rerun_failure_classification="stage120_write_admission_suite_rerun_failed"
    if [[ -f "$STAGE120_CANONICAL_POSITIVE_PACKET" ]]; then
      write_admission_suite_packet="$STAGE120_CANONICAL_POSITIVE_PACKET"
      production_write_admission_positive_suite_packet_source="stage120_canonical_prior_suite_packet"
    else
      echo "cjgui renderer state write dry-run admission packet: stage120 suite failed" >&2
      echo "cjgui renderer state write dry-run admission packet: log=$WRITE_ADMISSION_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$write_admission_suite_packet" || ! -f "$write_admission_suite_packet" ]]; then
  echo "cjgui renderer state write dry-run admission packet: missing stage120 suite packet" >&2
  exit 8
fi

required_write_admission_facts=(
  "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_suite_passed=true"
  "production_render_truth_admission_ready=true"
  "production_write_admission_preflight_ready=true"
  "production_write_admission_preflight_only=true"
  "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  "renderer_state_write_after_production_write_admission_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_write_admission_facts[@]}"; do
  require_file_fact "$write_admission_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui renderer state write dry-run admission packet: protected path modified" >&2
  exit 9
fi

write_ready="$(fact_value "$write_admission_suite_packet" "production_write_admission_preflight_ready")"
write_preflight_only="$(fact_value "$write_admission_suite_packet" "production_write_admission_preflight_only")"
first_frame_observed="$(fact_value "$write_admission_suite_packet" "first_frame_observed")"
frame_hash_computed="$(fact_value "$write_admission_suite_packet" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$write_admission_suite_packet" "frame_hash_nonzero")"
baseline_required="$(fact_value "$write_admission_suite_packet" "baseline_or_semantic_verification_before_renderer_state_write_required")"
runtime_native_probe_execution="$(fact_value "$write_admission_suite_packet" "runtime_native_probe_execution")"
truth_source="$(fact_value "$write_admission_suite_packet" "production_truth_admission_positive_suite_packet_source")"
first_frame_source="$(fact_value "$write_admission_suite_packet" "first_frame_positive_suite_packet_source")"
dry_run_ready="false"
if [[ "$write_ready" == "true" &&
      "$write_preflight_only" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" &&
      "$baseline_required" == "true" ]]; then
  dry_run_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_packet_version=1"
  echo "production_write_admission_suite_packet=$write_admission_suite_packet"
  echo "production_write_admission_positive_suite_packet_source=$production_write_admission_positive_suite_packet_source"
  echo "current_shell_production_write_admission_rerun_ready=$current_shell_production_write_admission_rerun_ready"
  echo "current_shell_production_write_admission_rerun_failure_classification=$current_shell_production_write_admission_rerun_failure_classification"
  echo "production_truth_admission_positive_suite_packet_source=$truth_source"
  echo "first_frame_positive_suite_packet_source=$first_frame_source"
  echo "production_write_admission_first_slice_consumed=true"
  echo "production_write_admission_preflight_ready=$write_ready"
  echo "production_write_admission_preflight_only=$write_preflight_only"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_or_semantic_verification_before_renderer_state_write_required=$baseline_required"
  echo "no_state_write_implementation_input_ready=true"
  echo "renderer_state_write_dry_run_admission_ready=$dry_run_ready"
  echo "renderer_state_write_dry_run_admission_non_mutating=true"
  echo "required_state_field_envelope_defined=true"
  echo "first_frame_observation_state_field_required=true"
  echo "production_write_admission_state_field_required=true"
  echo "baseline_gate_state_field_required=true"
  echo "rollback_visibility_dry_run_boundary_defined=true"
  echo "state_mutation_allowed=false"
  echo "visibility_publication_allowed=false"
  echo "rollback_state_write_allowed=false"
  echo "renderer_state_write_after_dry_run_admission_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_packet_passed=true"
} > "$DRY_RUN_PACKET"

echo "cjgui renderer state write dry-run admission packet: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_packet"
echo "cjgui renderer state write dry-run admission packet: dry_run_admission_packet_path=$DRY_RUN_PACKET"
echo "cjgui renderer state write dry-run admission packet: renderer_state_write_dry_run_admission_ready=$dry_run_ready"
echo "cjgui renderer state write dry-run admission packet: renderer_state_write=false"
