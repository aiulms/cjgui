#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage154 visibility publication bridge packet。它消费
# stage153 guarded executor bridge packet 与 legacy visibility denial packet，
# 输出 positive predicate map / fixture 已就绪但 runtime admission 仍阻断。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE154_PACKET_TMPDIR:-/tmp/cjgui-stage154-visibility-publication-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage154_visibility_publication_bridge_first_slice_owner.sh"
STAGE153_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_suite.sh"
LEGACY_VISIBILITY_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE153_LOG="$TMP_DIR/stage153.log"
LEGACY_VISIBILITY_LOG="$TMP_DIR/legacy-visibility.log"
RESULT_PACKET="$TMP_DIR/stage154-visibility-publication-bridge.packet"
STAGE153_SUITE_PACKET="${CJGUI_STAGE153_GUARDED_EXECUTOR_BRIDGE_SUITE_PACKET:-}"
LEGACY_VISIBILITY_PACKET="${CJGUI_STAGE128_VISIBILITY_PUBLICATION_DENIAL_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage153" "$TMP_DIR/legacy-visibility"
: > "$OWNER_LOG"
: > "$STAGE153_LOG"
: > "$LEGACY_VISIBILITY_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE153_SUITE_SCRIPT" "$LEGACY_VISIBILITY_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage154 visibility publication bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage154 visibility publication bridge packet: syntax check failed $script" >&2
    exit 4
  fi
done

fact_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}=" "$file" | tail -1 | cut -d= -f2- || true
}

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage154 visibility publication bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage154 visibility publication bridge packet: owner probe failed" >&2
  echo "cjgui stage154 visibility publication bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage154_visibility_publication_bridge_owner_present=true" \
  "stage153_guarded_executor_bridge_packet_required=true" \
  "legacy_visibility_publication_denial_packet_required=true" \
  "visibility_publication_positive_predicate_map_materialized=true" \
  "visibility_publication_admission_positive_fixture_defined=true" \
  "rollback_visibility_boundary_input_prepared=true" \
  "visibility_publication_bridge_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage153_input_mode="generated_stage153_suite_packet"
if [[ -n "$STAGE153_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE153_SUITE_PACKET" ]]; then
    echo "cjgui stage154 visibility publication bridge packet: provided stage153 suite packet missing $STAGE153_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage153_suite_packet_used=true" > "$STAGE153_LOG"
  stage153_input_mode="provided_stage153_suite_packet"
else
  if ! env CJGUI_STAGE153_TMPDIR="$TMP_DIR/stage153" zsh "$STAGE153_SUITE_SCRIPT" > "$STAGE153_LOG" 2>&1; then
    echo "cjgui stage154 visibility publication bridge packet: stage153 suite failed" >&2
    echo "cjgui stage154 visibility publication bridge packet: log=$STAGE153_LOG" >&2
    exit 8
  fi
  STAGE153_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE153_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE153_SUITE_PACKET" || ! -f "$STAGE153_SUITE_PACKET" ]]; then
  echo "cjgui stage154 visibility publication bridge packet: missing stage153 suite packet" >&2
  exit 9
fi
for fact in \
  "stage153_guarded_executor_bridge_after_mutation_request_bridge_first_slice_suite_passed=true" \
  "guarded_executor_bridge_ready=true" \
  "guarded_executor_bridge_runtime_admitted=false" \
  "visibility_publication_denial_input_prepared=true" \
  "visibility_publication_blocked=true" \
  "guarded_executor_denied=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE153_SUITE_PACKET" "$fact"
done

stage153_bridge_packet="$(fact_value "$STAGE153_SUITE_PACKET" "guarded_executor_bridge_packet")"
legacy_guarded_result_packet=""
if [[ -n "$stage153_bridge_packet" && -f "$stage153_bridge_packet" ]]; then
  legacy_guarded_result_packet="$(fact_value "$stage153_bridge_packet" "legacy_guarded_result_suite_packet")"
fi

legacy_visibility_input_mode="generated_legacy_visibility_packet"
if [[ -n "$LEGACY_VISIBILITY_PACKET" ]]; then
  if [[ ! -f "$LEGACY_VISIBILITY_PACKET" ]]; then
    echo "cjgui stage154 visibility publication bridge packet: provided legacy visibility packet missing $LEGACY_VISIBILITY_PACKET" >&2
    exit 10
  fi
  echo "provided_legacy_visibility_packet_used=true" > "$LEGACY_VISIBILITY_LOG"
  legacy_visibility_input_mode="provided_legacy_visibility_packet"
else
  if [[ -z "$legacy_guarded_result_packet" || ! -f "$legacy_guarded_result_packet" ]]; then
    echo "cjgui stage154 visibility publication bridge packet: missing stage153 legacy guarded result packet" >&2
    exit 11
  fi
  if ! env CJGUI_STAGE128_TMPDIR="$TMP_DIR/legacy-visibility" \
    CJGUI_SEMANTIC_COMPARISON_ADMITTED_GUARDED_STATE_WRITE_EXECUTOR_RESULT_ENVELOPE_FIRST_SLICE_SUITE_PACKET="$legacy_guarded_result_packet" \
    zsh "$LEGACY_VISIBILITY_PACKET_SCRIPT" > "$LEGACY_VISIBILITY_LOG" 2>&1; then
    echo "cjgui stage154 visibility publication bridge packet: legacy visibility packet failed" >&2
    echo "cjgui stage154 visibility publication bridge packet: log=$LEGACY_VISIBILITY_LOG" >&2
    exit 12
  fi
  LEGACY_VISIBILITY_PACKET="$(grep -Eo 'visibility_publication_denial_packet_path=[^[:space:]]+' "$LEGACY_VISIBILITY_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$LEGACY_VISIBILITY_PACKET" || ! -f "$LEGACY_VISIBILITY_PACKET" ]]; then
  echo "cjgui stage154 visibility publication bridge packet: missing legacy visibility packet" >&2
  exit 13
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_visibility_publication_denial_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_visibility_publication_denial_ready=true" \
  "visibility_publication_denial_envelope_materialized=true" \
  "visibility_publication_denied=true" \
  "rollback_fallback_denial_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$LEGACY_VISIBILITY_PACKET" "$fact"
done

stage153_route="$(fact_value "$STAGE153_SUITE_PACKET" "guarded_executor_bridge_route_classification")"
stage153_runtime_admitted="$(fact_value "$STAGE153_SUITE_PACKET" "guarded_executor_bridge_runtime_admitted")"
stage153_runtime_admitted="${stage153_runtime_admitted:-false}"
visibility_bridge_route="visibility_publication_bridge_source_ready_runtime_blocked_guarded_executor_bridge"
if [[ "$stage153_route" == "guarded_executor_bridge_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  visibility_bridge_route="visibility_publication_bridge_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$stage153_runtime_admitted" == "true" ]]; then
  visibility_bridge_route="visibility_publication_bridge_source_ready_runtime_blocked_visibility_publication_denied"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage154 visibility publication bridge packet: protected production bridge/state path modified" >&2
  exit 14
fi

{
  echo "stage154_visibility_publication_bridge_first_slice_packet_version=1"
  echo "stage153_input_mode=$stage153_input_mode"
  echo "legacy_visibility_input_mode=$legacy_visibility_input_mode"
  echo "stage153_suite_packet=$STAGE153_SUITE_PACKET"
  echo "stage153_guarded_executor_bridge_packet=$stage153_bridge_packet"
  echo "legacy_visibility_publication_denial_packet=$LEGACY_VISIBILITY_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage153_log=$STAGE153_LOG"
  echo "legacy_visibility_log=$LEGACY_VISIBILITY_LOG"
  echo "stage153_guarded_executor_bridge_packet_consumed=true"
  echo "legacy_visibility_publication_denial_packet_consumed=true"
  echo "stage153_guarded_executor_bridge_route_classification=$stage153_route"
  echo "guarded_executor_bridge_runtime_admitted=$stage153_runtime_admitted"
  echo "visibility_publication_bridge_ready=true"
  echo "visibility_publication_bridge_source_ready=true"
  echo "visibility_publication_bridge_runtime_admitted=false"
  echo "visibility_publication_bridge_route_classification=$visibility_bridge_route"
  echo "visibility_publication_positive_predicate_map_materialized=true"
  echo "visibility_publication_admission_positive_fixture_defined=true"
  echo "visibility_publication_admission_predicates_satisfied=false"
  echo "stage153_denial_input_bound_to_visibility_publication_envelope=true"
  echo "visibility_publication_denial_envelope_materialized=true"
  echo "visibility_publication_denied=true"
  echo "visibility_publication_blocked=true"
  echo "rollback_visibility_boundary_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=rollback_visibility_boundary_bridge_after_visibility_publication_bridge"
  echo "stage154_visibility_publication_bridge_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage154 visibility publication bridge packet: route_classification=$visibility_bridge_route"
echo "cjgui stage154 visibility publication bridge packet: visibility_publication_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage154 visibility publication bridge packet: renderer_state_write=false"
