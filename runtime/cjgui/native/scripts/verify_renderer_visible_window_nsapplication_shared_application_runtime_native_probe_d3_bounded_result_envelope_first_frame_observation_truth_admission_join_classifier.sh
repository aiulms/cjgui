#!/usr/bin/env zsh
#
# 维护注释：本脚本分类 stage118 first-frame observation truth-admission join
# packet。正向分类只表示 isolated first-frame observation 已进入 production
# truth/write-decision admission preflight；不表示 production render truth 或
# renderer-state write 已获准。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${TMPDIR:-/tmp}/cjgui-stage118-first-frame-observation-truth-admission-join-classifier"
PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet.sh"
PACKET_LOG="$TMP_DIR/packet.log"
CLASSIFIER_PACKET="$TMP_DIR/d3-bounded-result-envelope-first-frame-observation-truth-admission-join-classifier.packet"
JOIN_PACKET="${CJGUI_D3_BOUNDED_RESULT_ENVELOPE_FIRST_FRAME_OBSERVATION_TRUTH_ADMISSION_JOIN_PACKET:-}"

mkdir -p "$TMP_DIR"
: > "$PACKET_LOG"
: > "$CLASSIFIER_PACKET"

if [[ ! -x "$PACKET_SCRIPT" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: missing executable script $PACKET_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$PACKET_SCRIPT"; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: syntax check failed $PACKET_SCRIPT" >&2
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
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ -z "$JOIN_PACKET" ]]; then
  if ! env TMPDIR="$TMP_DIR/packet" zsh "$PACKET_SCRIPT" > "$PACKET_LOG" 2>&1; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: packet generation failed" >&2
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: log=$PACKET_LOG" >&2
    exit 6
  fi
  JOIN_PACKET="$(grep -Eo 'join_packet_path=[^[:space:]]+' "$PACKET_LOG" | tail -1 | cut -d= -f2-)"
else
  if [[ ! -f "$JOIN_PACKET" ]]; then
    echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: provided packet missing $JOIN_PACKET" >&2
    exit 7
  fi
  {
    echo "provided_join_packet_used=true"
    echo "join_packet_path=$JOIN_PACKET"
  } > "$PACKET_LOG"
fi

if [[ -z "$JOIN_PACKET" || ! -f "$JOIN_PACKET" ]]; then
  echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: missing join packet" >&2
  exit 8
fi

required_packet_facts=(
  "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_packet_passed=true"
  "renderer_state_write_decision_contract_ready=true"
  "truth_admission_join_is_not_production_render_truth=true"
  "production_truth_admission_after_join_preflight_required=true"
  "production_write_admission_after_truth_admission_join_required=true"
  "production_render_truth_after_join_preflight_allowed=false"
  "renderer_state_write_after_truth_admission_join_allowed=false"
  "result_envelope_promoted_to_production_truth=false"
  "production_render_truth=false"
  "renderer_state_write=false"
  "native_bridge_expansion=false"
  "production_public_c_abi_added=false"
)
for fact in "${required_packet_facts[@]}"; do
  require_file_fact "$JOIN_PACKET" "$fact"
done

positive_input="$(fact_value "$JOIN_PACKET" "positive_first_frame_observation_input_ready")"
join_ready="$(fact_value "$JOIN_PACKET" "first_frame_observation_truth_admission_join_preflight_ready")"
first_frame_observed="$(fact_value "$JOIN_PACKET" "first_frame_observed")"
frame_hash_computed="$(fact_value "$JOIN_PACKET" "frame_hash_computed")"
frame_hash_nonzero="$(fact_value "$JOIN_PACKET" "frame_hash_nonzero")"
stage117_failure_classification="$(fact_value "$JOIN_PACKET" "stage117_first_frame_observation_first_slice_failure_classification")"

classifier_route="blocked_first_frame_observation_truth_admission_join_preflight"
if [[ "$join_ready" == "true" &&
      "$positive_input" == "true" &&
      "$first_frame_observed" == "true" &&
      "$frame_hash_computed" == "true" &&
      "$frame_hash_nonzero" == "true" ]]; then
  classifier_route="admitted_bounded_first_frame_observation_truth_admission_join_preflight"
elif [[ "$positive_input" != "true" ]]; then
  classifier_route="first_frame_observation_input_missing"
fi

{
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_packet_version=1"
  echo "join_packet=$JOIN_PACKET"
  echo "d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier_passed=true"
  echo "first_frame_observation_truth_admission_join_classifier_route=$classifier_route"
  echo "positive_first_frame_observation_input_ready=$positive_input"
  echo "first_frame_observation_truth_admission_join_preflight_ready=$join_ready"
  echo "stage117_first_frame_observation_first_slice_failure_classification=$stage117_failure_classification"
  echo "first_frame_observed=$first_frame_observed"
  echo "frame_hash_computed=$frame_hash_computed"
  echo "frame_hash_nonzero=$frame_hash_nonzero"
  echo "frame_hash_persisted=false"
  echo "frame_hash_value_logged=false"
  echo "baseline_compared=false"
  echo "truth_admission_join_is_not_production_render_truth=true"
  echo "production_truth_admission_after_join_preflight_required=true"
  echo "production_write_admission_after_truth_admission_join_required=true"
  echo "production_render_truth_after_join_preflight_allowed=false"
  echo "renderer_state_write_after_truth_admission_join_allowed=false"
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

echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: route_classification=d3_bounded_result_envelope_first_frame_observation_truth_admission_join_classifier"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: classifier_packet_path=$CLASSIFIER_PACKET"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: first_frame_observation_truth_admission_join_classifier_route=$classifier_route"
echo "cjgui renderer NSApplication runtime native probe D3 bounded first-frame observation truth admission join classifier: renderer_state_write=false"
