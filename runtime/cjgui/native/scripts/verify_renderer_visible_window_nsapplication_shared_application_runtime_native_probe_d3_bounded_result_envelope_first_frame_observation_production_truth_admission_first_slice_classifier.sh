#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage119 production truth admission first-slice packet。
# admitted 只表示 production truth admission preflight 可继续，不表示 production
# render truth 或 renderer-state write 已成立。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage119-first-frame-observation-production-truth-admission-first-slice-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-production-truth-admission-first-slice-classifier.packet"
ADMISSION_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_PRODUCTION_TRUTH_ADMISSION_FIRST_SLICE_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$ADMISSION_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  ADMISSION_PACKET="$(grep -Eo 'admission_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$ADMISSION_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: provided packet missing $ADMISSION_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_admission_packet_used=true"
    echo "admission_packet_path=$ADMISSION_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$ADMISSION_PACKET" || ! -f "$ADMISSION_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: missing admission packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_packet_passed=true"
  "first_frame_observation_truth_admission_join_preflight_ready=true"
  "production_render_truth_admission_ready=true"
  "production_truth_admission_preflight_only=true"
  "baseline_or_semantic_verification_after_first_slice_required=true"
  "renderer_state_write_after_production_truth_admission_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "backend_ready_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$ADMISSION_PACKET" "$fact"
done

admission_ready="$(fact_value "$ADMISSION_PACKET" "production_render_truth_admission_ready")"
join_ready="$(fact_value "$ADMISSION_PACKET" "first_frame_observation_truth_admission_join_preflight_ready")"
first_frame_observed="$(fact_value "$ADMISSION_PACKET" "first_frame_observed")"
frame_hash_computed="$(fact_value "$ADMISSION_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$ADMISSION_PACKET" "frame_hash_nonzero")"
classifier_route="blocked_first_frame_observation_production_truth_admission_first_slice"
if [[ "$admission_ready" == "true" &&
      "$join_ready" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" ]]; then
  classifier_route="admitted_first_frame_observation_production_truth_admission_first_slice_preflight"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_classifier_packet_version=1"
  echo "admission_packet=$ADMISSION_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_classifier_passed=true"
  echo "first_frame_observation_production_truth_admission_classifier_route=$classifier_route"
  echo "first_frame_observation_truth_admission_join_preflight_ready=$join_ready"
  echo "production_render_truth_admission_ready=$admission_ready"
  echo "production_truth_admission_preflight_only=true"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "baseline_or_semantic_verification_after_first_slice_required=true"
  echo "production_write_admission_after_truth_admission_required=true"
  echo "renderer_state_write_after_production_truth_admission_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_production_truth_admission_first_slice_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: first_frame_observation_production_truth_admission_classifier_route=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation production truth admission classifier: renderer_state_write=false"
