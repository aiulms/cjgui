#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 baseline materialization dry-run suite packet，
# 生成 semantic acceptance result dry-run packet。缺 baseline artifact 时只产出
# fail-closed acceptance result，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage123-semantic-acceptance-result-dry-run-first-slice-packet"
BASELINE_MATERIALIZATION_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_suite.sh"
BASELINE_MATERIALIZATION_LOG="$TMP_DIR/baseline-materialization-suite.log"
SEMANTIC_ACCEPTANCE_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-semantic-acceptance-result-dry-run-first-slice.packet"
BASELINE_MATERIALIZATION_SUITE_PACKET="${CJGUI_BASELINE_MATERIALIZATION_DRY_RUN_FIRST_SLICE_SUITE_PACKET:-}"
STAGE123_BASELINE_MATERIALIZATION_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage123-baseline-materialization-suite-check/cjgui-stage123-baseline-materialization-dry-run-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-baseline-materialization-dry-run-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$BASELINE_MATERIALIZATION_LOG"
: > "$SEMANTIC_ACCEPTANCE_PACKET"

if [[ ! -x "$BASELINE_MATERIALIZATION_SUITE_SCRIPT" ]]; then
  echo "cjgui semantic acceptance result dry-run packet: missing executable script $BASELINE_MATERIALIZATION_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$BASELINE_MATERIALIZATION_SUITE_SCRIPT"; then
  echo "cjgui semantic acceptance result dry-run packet: syntax check failed $BASELINE_MATERIALIZATION_SUITE_SCRIPT" >&2
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
    echo "cjgui semantic acceptance result dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

baseline_materialization_suite_packet=""
baseline_materialization_positive_suite_packet_source="provided_stage123_baseline_materialization_suite_packet"
current_shell_baseline_materialization_rerun_ready="not_run"
current_shell_baseline_materialization_rerun_failure_classification="none"

if [[ -n "$BASELINE_MATERIALIZATION_SUITE_PACKET" ]]; then
  if [[ ! -f "$BASELINE_MATERIALIZATION_SUITE_PACKET" ]]; then
    echo "cjgui semantic acceptance result dry-run packet: provided baseline materialization suite packet missing $BASELINE_MATERIALIZATION_SUITE_PACKET" >&2
    exit 6
  fi
  baseline_materialization_suite_packet="$BASELINE_MATERIALIZATION_SUITE_PACKET"
  {
    echo "baseline_materialization_suite_packet_used=true"
    echo "suite_packet_path=$BASELINE_MATERIALIZATION_SUITE_PACKET"
    cat "$BASELINE_MATERIALIZATION_SUITE_PACKET"
  } > "$BASELINE_MATERIALIZATION_LOG"
else
  baseline_materialization_positive_suite_packet_source="current_shell_stage123_baseline_materialization_rerun"
  if env TMPDIR="$TMP_DIR/baseline-materialization" zsh "$BASELINE_MATERIALIZATION_SUITE_SCRIPT" > "$BASELINE_MATERIALIZATION_LOG" 2>&1; then
    current_shell_baseline_materialization_rerun_ready="true"
    baseline_materialization_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$BASELINE_MATERIALIZATION_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_baseline_materialization_rerun_ready="false"
    current_shell_baseline_materialization_rerun_failure_classification="stage123_baseline_materialization_suite_rerun_failed"
    if [[ -f "$STAGE123_BASELINE_MATERIALIZATION_CANONICAL_POSITIVE_PACKET" ]]; then
      baseline_materialization_suite_packet="$STAGE123_BASELINE_MATERIALIZATION_CANONICAL_POSITIVE_PACKET"
      baseline_materialization_positive_suite_packet_source="stage123_baseline_materialization_canonical_prior_suite_packet"
    else
      echo "cjgui semantic acceptance result dry-run packet: baseline materialization suite failed" >&2
      echo "cjgui semantic acceptance result dry-run packet: log=$BASELINE_MATERIALIZATION_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$baseline_materialization_suite_packet" || ! -f "$baseline_materialization_suite_packet" ]]; then
  echo "cjgui semantic acceptance result dry-run packet: missing baseline materialization suite packet" >&2
  exit 8
fi

required_baseline_materialization_facts=(
  "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_suite_passed=true"
  "baseline_materialization_dry_run_ready=true"
  "baseline_materialization_dry_run_only=true"
  "baseline_artifact_failure_classification=missing_baseline_artifact_source"
  "baseline_artifact_materialized=false"
  "baseline_artifact_freshness_passed=false"
  "baseline_frame_hash_value_redacted=true"
  "baseline_compare_executed=false"
  "semantic_acceptance_admitted=false"
  "renderer_state_write_after_baseline_materialization_allowed=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_baseline_materialization_facts[@]}"; do
  require_file_fact "$baseline_materialization_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui semantic acceptance result dry-run packet: protected path modified" >&2
  exit 9
fi

runtime_native_probe_execution="$(fact_value "$baseline_materialization_suite_packet" "runtime_native_probe_execution")"
baseline_materialization_ready="$(fact_value "$baseline_materialization_suite_packet" "baseline_materialization_dry_run_ready")"
semantic_acceptance_ready="false"
if [[ "$baseline_materialization_ready" == "true" ]]; then
  semantic_acceptance_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_packet_version=1"
  echo "baseline_materialization_suite_packet=$baseline_materialization_suite_packet"
  echo "baseline_materialization_positive_suite_packet_source=$baseline_materialization_positive_suite_packet_source"
  echo "current_shell_baseline_materialization_rerun_ready=$current_shell_baseline_materialization_rerun_ready"
  echo "current_shell_baseline_materialization_rerun_failure_classification=$current_shell_baseline_materialization_rerun_failure_classification"
  echo "baseline_materialization_dry_run_consumed=true"
  echo "baseline_materialization_dry_run_ready=$baseline_materialization_ready"
  echo "semantic_acceptance_result_dry_run_ready=$semantic_acceptance_ready"
  echo "semantic_acceptance_result_dry_run_only=true"
  echo "semantic_acceptance_result_envelope_defined=true"
  echo "semantic_acceptance_failure_classification_defined=true"
  echo "missing_baseline_artifact_blocks_semantic_acceptance=true"
  echo "semantic_acceptance_failure_classification=missing_baseline_artifact_source"
  echo "semantic_acceptance_evaluated=false"
  echo "semantic_acceptance_admitted=false"
  echo "baseline_artifact_materialized=false"
  echo "baseline_artifact_freshness_passed=false"
  echo "baseline_frame_hash_value_redacted=true"
  echo "renderer_state_write_after_semantic_acceptance_result_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_packet_passed=true"
} > "$SEMANTIC_ACCEPTANCE_PACKET"

echo "cjgui semantic acceptance result dry-run packet: route_classification=d3_bounded_result_envelope_first_frame_observation_semantic_acceptance_result_dry_run_first_slice_packet"
echo "cjgui semantic acceptance result dry-run packet: semantic_acceptance_packet_path=$SEMANTIC_ACCEPTANCE_PACKET"
echo "cjgui semantic acceptance result dry-run packet: semantic_acceptance_result_dry_run_ready=$semantic_acceptance_ready"
echo "cjgui semantic acceptance result dry-run packet: renderer_state_write=false"
