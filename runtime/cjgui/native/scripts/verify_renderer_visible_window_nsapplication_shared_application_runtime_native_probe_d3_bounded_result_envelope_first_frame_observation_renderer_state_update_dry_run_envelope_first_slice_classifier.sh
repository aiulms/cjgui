#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 state-update dry-run envelope packet。admitted 只表示
# envelope 可交接给下一段 baseline/semantic verification，不表示真实 state write。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage121-renderer-state-update-dry-run-envelope-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-update-dry-run-envelope-first-slice-classifier.packet"
STATE_UPDATE_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_UPDATE_DRY_RUN_ENVELOPE_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer state-update dry-run envelope classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer state-update dry-run envelope classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer state-update dry-run envelope classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$STATE_UPDATE_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer state-update dry-run envelope classifier: packet generation failed" >&2
    echo "cjgui renderer state-update dry-run envelope classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  STATE_UPDATE_PACKET="$(grep -Eo 'state_update_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$STATE_UPDATE_PACKET" ]]; then
    echo "cjgui renderer state-update dry-run envelope classifier: provided packet missing $STATE_UPDATE_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_state_update_packet_used=true"
    echo "state_update_packet_path=$STATE_UPDATE_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$STATE_UPDATE_PACKET" || ! -f "$STATE_UPDATE_PACKET" ]]; then
  echo "cjgui renderer state-update dry-run envelope classifier: missing state-update packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_packet_passed=true"
  "renderer_state_update_dry_run_envelope_ready=true"
  "state_update_envelope_dry_run_only=true"
  "production_write_preflight_mapped_to_state_update_candidate=true"
  "first_frame_observation_state_field_mapped=true"
  "frame_hash_summary_state_field_mapped=true"
  "baseline_gate_state_field_mapped=true"
  "rollback_visibility_boundary_state_field_mapped=true"
  "state_mutation_request_fail_closed=true"
  "visibility_publication_fail_closed=true"
  "rollback_fallback_write_fail_closed=true"
  "frame_hash_value_persisted=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$STATE_UPDATE_PACKET" "$fact"
done

state_update_ready="$(fact_value "$STATE_UPDATE_PACKET" "renderer_state_update_dry_run_envelope_ready")"
dry_run_only="$(fact_value "$STATE_UPDATE_PACKET" "state_update_envelope_dry_run_only")"
state_fail_closed="$(fact_value "$STATE_UPDATE_PACKET" "state_mutation_request_fail_closed")"
visibility_fail_closed="$(fact_value "$STATE_UPDATE_PACKET" "visibility_publication_fail_closed")"
rollback_fail_closed="$(fact_value "$STATE_UPDATE_PACKET" "rollback_fallback_write_fail_closed")"
classifier_route="blocked_renderer_state_update_dry_run_envelope_first_slice"
if [[ "$state_update_ready" == "true" &&
      "$dry_run_only" == "true" &&
      "$state_fail_closed" == "true" &&
      "$visibility_fail_closed" == "true" &&
      "$rollback_fail_closed" == "true" ]]; then
  classifier_route="admitted_renderer_state_update_dry_run_envelope_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier_packet_version=1"
  echo "state_update_packet=$STATE_UPDATE_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier_passed=true"
  echo "renderer_state_update_dry_run_envelope_classifier_route=$classifier_route"
  echo "renderer_state_update_dry_run_envelope_ready=$state_update_ready"
  echo "state_update_envelope_dry_run_only=$dry_run_only"
  echo "production_write_preflight_mapped_to_state_update_candidate=true"
  echo "first_frame_observation_state_field_mapped=true"
  echo "frame_hash_summary_state_field_mapped=true"
  echo "baseline_gate_state_field_mapped=true"
  echo "rollback_visibility_boundary_state_field_mapped=true"
  echo "state_mutation_request_fail_closed=$state_fail_closed"
  echo "visibility_publication_fail_closed=$visibility_fail_closed"
  echo "rollback_fallback_write_fail_closed=$rollback_fail_closed"
  echo "frame_hash_value_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "state_mutation_allowed=false"
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

echo "cjgui renderer state-update dry-run envelope classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_update_dry_run_envelope_first_slice_classifier"
echo "cjgui renderer state-update dry-run envelope classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer state-update dry-run envelope classifier: renderer_state_update_dry_run_envelope_classifier_route=$classifier_route"
echo "cjgui renderer state-update dry-run envelope classifier: renderer_state_write=false"
