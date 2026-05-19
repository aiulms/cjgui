#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage120 production write admission first-slice packet。
# admitted 只表示 production write admission preflight 可继续，不表示 renderer
# state write、runtime state write 或 backend-ready truth 已成立。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage120-first-frame-observation-production-write-admission-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-production-write-admission-first-slice-classifier.packet"
WRITE_ADMISSION_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_WRITE_ADMISSION_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$WRITE_ADMISSION_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  WRITE_ADMISSION_PACKET="$(grep -Eo 'write_admission_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$WRITE_ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: provided packet missing $WRITE_ADMISSION_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_write_admission_packet_used=true"
    echo "write_admission_packet_path=$WRITE_ADMISSION_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$WRITE_ADMISSION_PACKET" || ! -f "$WRITE_ADMISSION_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: missing write admission packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_packet_passed=true"
  "production_render_truth_admission_ready=true"
  "production_truth_admission_preflight_only=true"
  "production_write_admission_preflight_ready=true"
  "production_write_admission_preflight_only=true"
  "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  "renderer_state_write_after_production_truth_admission_allowed=false"
  "renderer_state_write_after_production_write_admission_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "runtime_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$WRITE_ADMISSION_PACKET" "$fact"
done

write_ready="$(fact_value "$WRITE_ADMISSION_PACKET" "production_write_admission_preflight_ready")"
truth_ready="$(fact_value "$WRITE_ADMISSION_PACKET" "production_render_truth_admission_ready")"
preflight_only="$(fact_value "$WRITE_ADMISSION_PACKET" "production_write_admission_preflight_only")"
first_frame_observed="$(fact_value "$WRITE_ADMISSION_PACKET" "first_frame_observed")"
frame_hash_computed="$(fact_value "$WRITE_ADMISSION_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$WRITE_ADMISSION_PACKET" "frame_hash_nonzero")"
classifier_route="blocked_first_frame_observation_production_write_admission_first_slice"
if [[ "$write_ready" == "true" &&
      "$truth_ready" == "true" &&
      "$preflight_only" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" ]]; then
  classifier_route="admitted_first_frame_observation_production_write_admission_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier_packet_version=1"
  echo "write_admission_packet=$WRITE_ADMISSION_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier_passed=true"
  echo "first_frame_observation_production_write_admission_classifier_route=$classifier_route"
  echo "production_render_truth_admission_ready=$truth_ready"
  echo "production_write_admission_preflight_ready=$write_ready"
  echo "production_write_admission_preflight_only=$preflight_only"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_or_semantic_verification_before_renderer_state_write_required=true"
  echo "renderer_state_write_after_production_truth_admission_allowed=false"
  echo "renderer_state_write_after_production_write_admission_allowed=false"
  echo "result_envelope_promoted_to_production_truth=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_production_write_admission_first_slice_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: first_frame_observation_production_write_admission_classifier_route=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production write admission classifier: renderer_state_write=false"
