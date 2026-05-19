#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 renderer-state semantic gate dry-run envelope packet。
# blocked route 是期望结果：缺 baseline 与 semantic acceptance pending 时不能写 state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage122-renderer-state-semantic-gate-dry-run-envelope-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-semantic-gate-dry-run-envelope-first-slice-classifier.packet"
SEMANTIC_GATE_PACKET="${CJGUI_RENDERER_STATE_SEMANTIC_GATE_DRY_RUN_ENVELOPE_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer state semantic gate dry-run envelope classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer state semantic gate dry-run envelope classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer state semantic gate dry-run envelope classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$SEMANTIC_GATE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer state semantic gate dry-run envelope classifier: packet generation failed" >&2
    echo "cjgui renderer state semantic gate dry-run envelope classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  SEMANTIC_GATE_PACKET="$(grep -Eo 'semantic_gate_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$SEMANTIC_GATE_PACKET" ]]; then
    echo "cjgui renderer state semantic gate dry-run envelope classifier: provided packet missing $SEMANTIC_GATE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_semantic_gate_packet_used=true"
    echo "semantic_gate_packet_path=$SEMANTIC_GATE_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$SEMANTIC_GATE_PACKET" || ! -f "$SEMANTIC_GATE_PACKET" ]]; then
  echo "cjgui renderer state semantic gate dry-run envelope classifier: missing semantic gate packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_packet_passed=true"
  "renderer_state_semantic_gate_dry_run_envelope_ready=true"
  "semantic_gate_dry_run_only=true"
  "baseline_compare_required_before_renderer_state_write=true"
  "semantic_acceptance_required_before_renderer_state_write=true"
  "missing_baseline_blocks_renderer_state_write=true"
  "semantic_acceptance_pending_blocks_renderer_state_write=true"
  "renderer_state_write_admission_after_semantic_gate=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$SEMANTIC_GATE_PACKET" "$fact"
done

semantic_gate_ready="$(fact_value "$SEMANTIC_GATE_PACKET" "renderer_state_semantic_gate_dry_run_envelope_ready")"
missing_baseline_blocks="$(fact_value "$SEMANTIC_GATE_PACKET" "missing_baseline_blocks_renderer_state_write")"
semantic_pending_blocks="$(fact_value "$SEMANTIC_GATE_PACKET" "semantic_acceptance_pending_blocks_renderer_state_write")"
state_write_after_gate="$(fact_value "$SEMANTIC_GATE_PACKET" "renderer_state_write_admission_after_semantic_gate")"
classifier_route="failed_renderer_state_semantic_gate_dry_run_envelope_first_slice"
if [[ "$semantic_gate_ready" == "true" &&
      "$missing_baseline_blocks" == "true" &&
      "$semantic_pending_blocks" == "true" &&
      "$state_write_after_gate" == "false" ]]; then
  classifier_route="blocked_renderer_state_semantic_gate_dry_run_pending_baseline_verification"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_classifier_packet_version=1"
  echo "semantic_gate_packet=$SEMANTIC_GATE_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_classifier_passed=true"
  echo "renderer_state_semantic_gate_dry_run_envelope_classifier_route=$classifier_route"
  echo "renderer_state_semantic_gate_dry_run_envelope_ready=$semantic_gate_ready"
  echo "semantic_gate_dry_run_only=true"
  echo "baseline_compare_required_before_renderer_state_write=true"
  echo "semantic_acceptance_required_before_renderer_state_write=true"
  echo "missing_baseline_blocks_renderer_state_write=$missing_baseline_blocks"
  echo "semantic_acceptance_pending_blocks_renderer_state_write=$semantic_pending_blocks"
  echo "renderer_state_write_decision_blocked_until_semantic_acceptance=true"
  echo "renderer_state_write_admission_after_semantic_gate=$state_write_after_gate"
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

echo "cjgui renderer state semantic gate dry-run envelope classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_semantic_gate_dry_run_envelope_first_slice_classifier"
echo "cjgui renderer state semantic gate dry-run envelope classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer state semantic gate dry-run envelope classifier: renderer_state_semantic_gate_dry_run_envelope_classifier_route=$classifier_route"
echo "cjgui renderer state semantic gate dry-run envelope classifier: renderer_state_write=false"
