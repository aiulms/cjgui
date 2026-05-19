#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 renderer-state write dry-run admission packet。admitted
# 只表示 non-mutating dry-run 可以进入 state-update envelope，不表示真实写入许可。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage121-renderer-state-write-dry-run-admission-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-renderer-state-write-dry-run-admission-first-slice-classifier.packet"
DRY_RUN_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_RENDERER_STATE_WRITE_DRY_RUN_ADMISSION_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer state write dry-run admission classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer state write dry-run admission classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer state write dry-run admission classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$DRY_RUN_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer state write dry-run admission classifier: packet generation failed" >&2
    echo "cjgui renderer state write dry-run admission classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  DRY_RUN_PACKET="$(grep -Eo 'dry_run_admission_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$DRY_RUN_PACKET" ]]; then
    echo "cjgui renderer state write dry-run admission classifier: provided packet missing $DRY_RUN_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_dry_run_admission_packet_used=true"
    echo "dry_run_admission_packet_path=$DRY_RUN_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$DRY_RUN_PACKET" || ! -f "$DRY_RUN_PACKET" ]]; then
  echo "cjgui renderer state write dry-run admission classifier: missing dry-run packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_packet_passed=true"
  "production_write_admission_preflight_ready=true"
  "production_write_admission_preflight_only=true"
  "renderer_state_write_dry_run_admission_ready=true"
  "renderer_state_write_dry_run_admission_non_mutating=true"
  "required_state_field_envelope_defined=true"
  "first_frame_observation_state_field_required=true"
  "production_write_admission_state_field_required=true"
  "baseline_gate_state_field_required=true"
  "rollback_visibility_dry_run_boundary_defined=true"
  "state_mutation_allowed=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$DRY_RUN_PACKET" "$fact"
done

dry_run_ready="$(fact_value "$DRY_RUN_PACKET" "renderer_state_write_dry_run_admission_ready")"
non_mutating="$(fact_value "$DRY_RUN_PACKET" "renderer_state_write_dry_run_admission_non_mutating")"
required_fields="$(fact_value "$DRY_RUN_PACKET" "required_state_field_envelope_defined")"
rollback_boundary="$(fact_value "$DRY_RUN_PACKET" "rollback_visibility_dry_run_boundary_defined")"
classifier_route="blocked_renderer_state_write_dry_run_admission_first_slice"
if [[ "$dry_run_ready" == "true" &&
      "$non_mutating" == "true" &&
      "$required_fields" == "true" &&
      "$rollback_boundary" == "true" ]]; then
  classifier_route="admitted_renderer_state_write_dry_run_admission_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_classifier_packet_version=1"
  echo "dry_run_admission_packet=$DRY_RUN_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_classifier_passed=true"
  echo "renderer_state_write_dry_run_admission_classifier_route=$classifier_route"
  echo "renderer_state_write_dry_run_admission_ready=$dry_run_ready"
  echo "renderer_state_write_dry_run_admission_non_mutating=$non_mutating"
  echo "required_state_field_envelope_defined=$required_fields"
  echo "first_frame_observation_state_field_required=true"
  echo "production_write_admission_state_field_required=true"
  echo "baseline_gate_state_field_required=true"
  echo "rollback_visibility_dry_run_boundary_defined=$rollback_boundary"
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

echo "cjgui renderer state write dry-run admission classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_renderer_state_write_dry_run_admission_first_slice_classifier"
echo "cjgui renderer state write dry-run admission classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer state write dry-run admission classifier: renderer_state_write_dry_run_admission_classifier_route=$classifier_route"
echo "cjgui renderer state write dry-run admission classifier: renderer_state_write=false"
