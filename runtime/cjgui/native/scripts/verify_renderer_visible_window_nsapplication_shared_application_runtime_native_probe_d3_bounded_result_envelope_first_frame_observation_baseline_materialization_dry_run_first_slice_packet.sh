#!/usr/bin/env zsh
#
# 维护注释：本脚本消费 stage122 renderer-state semantic gate suite packet，
# 生成 baseline materialization dry-run packet。它只定义 baseline artifact
# source / freshness / redaction / missing-baseline classification，不读真实
# baseline，不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage123-baseline-materialization-dry-run-first-slice-packet"
SEMANTIC_GATE_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_suite.sh"
SEMANTIC_GATE_LOG="$TMP_DIR/semantic-gate-suite.log"
BASELINE_MATERIALIZATION_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-baseline-materialization-dry-run-first-slice.packet"
SEMANTIC_GATE_SUITE_PACKET="${CJGUI_RENDERER_STATE_SEMANTIC_GATE_DRY_RUN_ENVELOPE_FIRST_SLICE_SUITE_PACKET:-}"
STAGE122_SEMANTIC_GATE_CANONICAL_POSITIVE_PACKET="/tmp/cjgui-stage122-semantic-gate-suite-check/cjgui-stage122-renderer-state-semantic-gate-dry-run-envelope-first-slice-suite/d3-bounded-result-envelope-first-frame-observation-renderer-state-semantic-gate-dry-run-envelope-first-slice-suite.packet"

mkdir -p "$TMP_DIR"
: > "$SEMANTIC_GATE_LOG"
: > "$BASELINE_MATERIALIZATION_PACKET"

if [[ ! -x "$SEMANTIC_GATE_SUITE_SCRIPT" ]]; then
  echo "cjgui baseline materialization dry-run packet: missing executable script $SEMANTIC_GATE_SUITE_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$SEMANTIC_GATE_SUITE_SCRIPT"; then
  echo "cjgui baseline materialization dry-run packet: syntax check failed $SEMANTIC_GATE_SUITE_SCRIPT" >&2
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
    echo "cjgui baseline materialization dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

semantic_gate_suite_packet=""
semantic_gate_positive_suite_packet_source="provided_stage122_semantic_gate_suite_packet"
current_shell_semantic_gate_rerun_ready="not_run"
current_shell_semantic_gate_rerun_failure_classification="none"

if [[ -n "$SEMANTIC_GATE_SUITE_PACKET" ]]; then
  if [[ ! -f "$SEMANTIC_GATE_SUITE_PACKET" ]]; then
    echo "cjgui baseline materialization dry-run packet: provided semantic gate suite packet missing $SEMANTIC_GATE_SUITE_PACKET" >&2
    exit 6
  fi
  semantic_gate_suite_packet="$SEMANTIC_GATE_SUITE_PACKET"
  {
    echo "semantic_gate_suite_packet_used=true"
    echo "suite_packet_path=$SEMANTIC_GATE_SUITE_PACKET"
    cat "$SEMANTIC_GATE_SUITE_PACKET"
  } > "$SEMANTIC_GATE_LOG"
else
  semantic_gate_positive_suite_packet_source="current_shell_stage122_semantic_gate_rerun"
  if env TMPDIR="$TMP_DIR/semantic-gate" zsh "$SEMANTIC_GATE_SUITE_SCRIPT" > "$SEMANTIC_GATE_LOG" 2>&1; then
    current_shell_semantic_gate_rerun_ready="true"
    semantic_gate_suite_packet="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$SEMANTIC_GATE_LOG" | tail -1 | cut -d= -f2-)"
  else
    current_shell_semantic_gate_rerun_ready="false"
    current_shell_semantic_gate_rerun_failure_classification="stage122_semantic_gate_suite_rerun_failed"
    if [[ -f "$STAGE122_SEMANTIC_GATE_CANONICAL_POSITIVE_PACKET" ]]; then
      semantic_gate_suite_packet="$STAGE122_SEMANTIC_GATE_CANONICAL_POSITIVE_PACKET"
      semantic_gate_positive_suite_packet_source="stage122_semantic_gate_canonical_prior_suite_packet"
    else
      echo "cjgui baseline materialization dry-run packet: semantic gate suite failed" >&2
      echo "cjgui baseline materialization dry-run packet: log=$SEMANTIC_GATE_LOG" >&2
      exit 7
    fi
  fi
fi

if [[ -z "$semantic_gate_suite_packet" || ! -f "$semantic_gate_suite_packet" ]]; then
  echo "cjgui baseline materialization dry-run packet: missing semantic gate suite packet" >&2
  exit 8
fi

required_semantic_gate_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_suite_passed=true"
  "renderer_state_semantic_gate_dry_run_envelope_ready=true"
  "semantic_gate_dry_run_only=true"
  "baseline_compare_required_before_renderer_state_write=true"
  "semantic_acceptance_required_before_renderer_state_write=true"
  "missing_baseline_blocks_renderer_state_write=true"
  "semantic_acceptance_pending_blocks_renderer_state_write=true"
  "renderer_state_write_admission_after_semantic_gate=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_semantic_gate_facts[@]}"; do
  require_file_fact "$semantic_gate_suite_packet" "$fact"
done

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj | grep . >/dev/null 2>&1; then
  echo "cjgui baseline materialization dry-run packet: protected path modified" >&2
  exit 9
fi

runtime_native_probe_execution="$(fact_value "$semantic_gate_suite_packet" "runtime_native_probe_execution")"
semantic_gate_ready="$(fact_value "$semantic_gate_suite_packet" "renderer_state_semantic_gate_dry_run_envelope_ready")"
baseline_materialization_ready="false"
if [[ "$semantic_gate_ready" == "true" ]]; then
  baseline_materialization_ready="true"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_packet_version=1"
  echo "semantic_gate_suite_packet=$semantic_gate_suite_packet"
  echo "semantic_gate_positive_suite_packet_source=$semantic_gate_positive_suite_packet_source"
  echo "current_shell_semantic_gate_rerun_ready=$current_shell_semantic_gate_rerun_ready"
  echo "current_shell_semantic_gate_rerun_failure_classification=$current_shell_semantic_gate_rerun_failure_classification"
  echo "renderer_state_semantic_gate_dry_run_envelope_consumed=true"
  echo "renderer_state_semantic_gate_dry_run_envelope_ready=$semantic_gate_ready"
  echo "baseline_materialization_dry_run_ready=$baseline_materialization_ready"
  echo "baseline_materialization_dry_run_only=true"
  echo "baseline_artifact_source_contract_defined=true"
  echo "baseline_artifact_freshness_contract_defined=true"
  echo "baseline_hash_value_redaction_policy_defined=true"
  echo "missing_baseline_artifact_source_classified=true"
  echo "baseline_artifact_failure_classification=missing_baseline_artifact_source"
  echo "baseline_artifact_source_available=false"
  echo "baseline_artifact_materialized=false"
  echo "baseline_artifact_freshness_checked=false"
  echo "baseline_artifact_freshness_passed=false"
  echo "baseline_frame_hash_value_redacted=true"
  echo "baseline_compare_executed=false"
  echo "semantic_acceptance_admitted=false"
  echo "semantic_acceptance_required_before_renderer_state_write=true"
  echo "renderer_state_write_after_baseline_materialization_allowed=false"
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
  echo "d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_packet_passed=true"
} > "$BASELINE_MATERIALIZATION_PACKET"

echo "cjgui baseline materialization dry-run packet: route_classification=d3_bounded_result_envelope_first_frame_observation_baseline_materialization_dry_run_first_slice_packet"
echo "cjgui baseline materialization dry-run packet: baseline_materialization_packet_path=$BASELINE_MATERIALIZATION_PACKET"
echo "cjgui baseline materialization dry-run packet: baseline_materialization_dry_run_ready=$baseline_materialization_ready"
echo "cjgui baseline materialization dry-run packet: renderer_state_write=false"
