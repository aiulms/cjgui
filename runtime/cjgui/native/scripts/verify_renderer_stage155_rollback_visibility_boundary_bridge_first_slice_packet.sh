#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage155 rollback visibility boundary bridge packet。
# 它消费 stage154 packet 与 legacy rollback denial packet，输出 rollback /
# visibility boundary 的 positive predicate map 与 state-write first-slice input。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE155_PACKET_TMPDIR:-/tmp/cjgui-stage155-rollback-visibility-boundary-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage155_rollback_visibility_boundary_bridge_first_slice_owner.sh"
STAGE154_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage154_visibility_publication_bridge_first_slice_suite.sh"
LEGACY_ROLLBACK_PACKET_SCRIPT="$SCRIPT_DIR/verify_renderer_visible_window_nsapplication_shared_application_runtime_native_probe_d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE154_LOG="$TMP_DIR/stage154.log"
LEGACY_ROLLBACK_LOG="$TMP_DIR/legacy-rollback.log"
RESULT_PACKET="$TMP_DIR/stage155-rollback-visibility-boundary-bridge.packet"
STAGE154_SUITE_PACKET="${CJGUI_STAGE154_VISIBILITY_PUBLICATION_BRIDGE_SUITE_PACKET:-}"
LEGACY_ROLLBACK_PACKET="${CJGUI_STAGE128_ROLLBACK_FALLBACK_DENIAL_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage154" "$TMP_DIR/legacy-rollback"
: > "$OWNER_LOG"
: > "$STAGE154_LOG"
: > "$LEGACY_ROLLBACK_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE154_SUITE_SCRIPT" "$LEGACY_ROLLBACK_PACKET_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage155 rollback visibility boundary bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage155 rollback visibility boundary bridge packet: owner probe failed" >&2
  echo "cjgui stage155 rollback visibility boundary bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage155_rollback_visibility_boundary_bridge_owner_present=true" \
  "stage154_visibility_publication_bridge_packet_required=true" \
  "legacy_rollback_fallback_denial_packet_required=true" \
  "rollback_visibility_positive_predicate_map_materialized=true" \
  "rollback_visibility_boundary_positive_fixture_defined=true" \
  "renderer_state_write_first_slice_input_prepared=true" \
  "rollback_visibility_boundary_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage154_input_mode="generated_stage154_suite_packet"
if [[ -n "$STAGE154_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE154_SUITE_PACKET" ]]; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: provided stage154 suite packet missing $STAGE154_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage154_suite_packet_used=true" > "$STAGE154_LOG"
  stage154_input_mode="provided_stage154_suite_packet"
else
  if ! env CJGUI_STAGE154_TMPDIR="$TMP_DIR/stage154" zsh "$STAGE154_SUITE_SCRIPT" > "$STAGE154_LOG" 2>&1; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: stage154 suite failed" >&2
    echo "cjgui stage155 rollback visibility boundary bridge packet: log=$STAGE154_LOG" >&2
    exit 8
  fi
  STAGE154_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE154_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE154_SUITE_PACKET" || ! -f "$STAGE154_SUITE_PACKET" ]]; then
  echo "cjgui stage155 rollback visibility boundary bridge packet: missing stage154 suite packet" >&2
  exit 9
fi
for fact in \
  "stage154_visibility_publication_bridge_first_slice_suite_passed=true" \
  "visibility_publication_bridge_ready=true" \
  "visibility_publication_bridge_runtime_admitted=false" \
  "visibility_publication_positive_predicate_map_materialized=true" \
  "visibility_publication_admission_positive_fixture_defined=true" \
  "rollback_visibility_boundary_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE154_SUITE_PACKET" "$fact"
done

stage154_bridge_packet="$(fact_value "$STAGE154_SUITE_PACKET" "visibility_publication_bridge_packet")"
legacy_visibility_packet=""
if [[ -n "$stage154_bridge_packet" && -f "$stage154_bridge_packet" ]]; then
  legacy_visibility_packet="$(fact_value "$stage154_bridge_packet" "legacy_visibility_publication_denial_packet")"
fi

legacy_rollback_input_mode="generated_legacy_rollback_packet"
if [[ -n "$LEGACY_ROLLBACK_PACKET" ]]; then
  if [[ ! -f "$LEGACY_ROLLBACK_PACKET" ]]; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: provided legacy rollback packet missing $LEGACY_ROLLBACK_PACKET" >&2
    exit 10
  fi
  echo "provided_legacy_rollback_packet_used=true" > "$LEGACY_ROLLBACK_LOG"
  legacy_rollback_input_mode="provided_legacy_rollback_packet"
else
  if [[ -z "$legacy_visibility_packet" || ! -f "$legacy_visibility_packet" ]]; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: missing stage154 legacy visibility packet" >&2
    exit 11
  fi
  if ! env CJGUI_STAGE128_TMPDIR="$TMP_DIR/legacy-rollback" \
    CJGUI_SEMANTIC_COMPARISON_ADMITTED_RENDERER_STATE_VISIBILITY_PUBLICATION_DENIAL_FIRST_SLICE_PACKET="$legacy_visibility_packet" \
    zsh "$LEGACY_ROLLBACK_PACKET_SCRIPT" > "$LEGACY_ROLLBACK_LOG" 2>&1; then
    echo "cjgui stage155 rollback visibility boundary bridge packet: legacy rollback packet failed" >&2
    echo "cjgui stage155 rollback visibility boundary bridge packet: log=$LEGACY_ROLLBACK_LOG" >&2
    exit 12
  fi
  LEGACY_ROLLBACK_PACKET="$(grep -Eo 'rollback_fallback_denial_envelope_packet_path=[^[:space:]]+' "$LEGACY_ROLLBACK_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$LEGACY_ROLLBACK_PACKET" || ! -f "$LEGACY_ROLLBACK_PACKET" ]]; then
  echo "cjgui stage155 rollback visibility boundary bridge packet: missing legacy rollback packet" >&2
  exit 13
fi
for fact in \
  "d3_bounded_result_envelope_first_frame_observation_semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_first_slice_packet_passed=true" \
  "semantic_comparison_admitted_renderer_state_rollback_fallback_denial_envelope_ready=true" \
  "visibility_denial_bound_to_rollback_fallback_stop_line=true" \
  "rollback_fallback_state_write_denied=true" \
  "terminal_write_denial_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$LEGACY_ROLLBACK_PACKET" "$fact"
done

stage154_route="$(fact_value "$STAGE154_SUITE_PACKET" "visibility_publication_bridge_route_classification")"
stage154_runtime_admitted="$(fact_value "$STAGE154_SUITE_PACKET" "visibility_publication_bridge_runtime_admitted")"
stage154_runtime_admitted="${stage154_runtime_admitted:-false}"
rollback_bridge_route="rollback_visibility_boundary_source_ready_runtime_blocked_visibility_publication_bridge"
if [[ "$stage154_route" == "visibility_publication_bridge_source_ready_runtime_blocked_host_metal_device_unavailable" ]]; then
  rollback_bridge_route="rollback_visibility_boundary_source_ready_runtime_blocked_host_metal_device_unavailable"
elif [[ "$stage154_runtime_admitted" == "true" ]]; then
  rollback_bridge_route="rollback_visibility_boundary_source_ready_runtime_blocked_rollback_denial"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage155 rollback visibility boundary bridge packet: protected production bridge/state path modified" >&2
  exit 14
fi

{
  echo "stage155_rollback_visibility_boundary_bridge_first_slice_packet_version=1"
  echo "stage154_input_mode=$stage154_input_mode"
  echo "legacy_rollback_input_mode=$legacy_rollback_input_mode"
  echo "stage154_suite_packet=$STAGE154_SUITE_PACKET"
  echo "stage154_visibility_publication_bridge_packet=$stage154_bridge_packet"
  echo "legacy_rollback_fallback_denial_packet=$LEGACY_ROLLBACK_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage154_log=$STAGE154_LOG"
  echo "legacy_rollback_log=$LEGACY_ROLLBACK_LOG"
  echo "stage154_visibility_publication_bridge_packet_consumed=true"
  echo "legacy_rollback_fallback_denial_packet_consumed=true"
  echo "stage154_visibility_publication_bridge_route_classification=$stage154_route"
  echo "visibility_publication_bridge_runtime_admitted=$stage154_runtime_admitted"
  echo "rollback_visibility_boundary_bridge_ready=true"
  echo "rollback_visibility_boundary_bridge_source_ready=true"
  echo "rollback_visibility_boundary_runtime_admitted=false"
  echo "rollback_visibility_boundary_route_classification=$rollback_bridge_route"
  echo "rollback_visibility_positive_predicate_map_materialized=true"
  echo "rollback_visibility_boundary_positive_fixture_defined=true"
  echo "rollback_visibility_boundary_predicates_satisfied=false"
  echo "visibility_publication_bridge_bound_to_rollback_boundary=true"
  echo "rollback_fallback_state_write_denied=true"
  echo "terminal_write_denial_input_prepared=true"
  echo "renderer_state_write_first_slice_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=renderer_state_write_first_slice_readiness_contract_after_rollback_visibility_boundary"
  echo "stage155_rollback_visibility_boundary_bridge_first_slice_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage155 rollback visibility boundary bridge packet: route_classification=$rollback_bridge_route"
echo "cjgui stage155 rollback visibility boundary bridge packet: rollback_visibility_boundary_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage155 rollback visibility boundary bridge packet: renderer_state_write=false"
