#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage176 visibility-not-published boundary packet，
# 消费 stage175 rollback-ready result suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE176_PACKET_TMPDIR:-/tmp/cjgui-stage176-renderer-state-write-visibility-not-published-boundary-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage176_renderer_state_write_visibility_not_published_boundary_first_slice_owner.sh"
STAGE175_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE175_LOG="$TMP_DIR/stage175.log"
RESULT_PACKET="$TMP_DIR/stage176-renderer-state-write-visibility-not-published-boundary-first-slice.packet"
STAGE175_SUITE_PACKET="${CJGUI_STAGE175_RENDERER_STATE_WRITE_ROLLBACK_READY_RESULT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage175"
: > "$OWNER_LOG"
: > "$STAGE175_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE175_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: syntax check failed $script" >&2
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
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: owner probe failed" >&2
  echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage176_renderer_state_write_visibility_not_published_boundary_owner_present=true" \
  "stage175_rollback_ready_result_required=true" \
  "visibility_not_published_boundary_materialized=true" \
  "rollback_ready_result_to_visibility_stop_line_bound=true" \
  "internal_visibility_shadow_only=true" \
  "stage177_renderer_state_write_first_slice_readiness_decision_input_prepared=true" \
  "visibility_publication_internal_only=true" \
  "renderer_state_write_visibility_not_published_boundary_ready=true" \
  "renderer_state_write_visibility_not_published_boundary_runtime_admitted=false" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage175_input_mode="generated_stage175_suite_packet"
if [[ -n "$STAGE175_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE175_SUITE_PACKET" ]]; then
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: provided stage175 suite packet missing $STAGE175_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage175_suite_packet_used=true" > "$STAGE175_LOG"
  stage175_input_mode="provided_stage175_suite_packet"
else
  if ! env CJGUI_STAGE175_TMPDIR="$TMP_DIR/stage175" zsh "$STAGE175_SUITE_SCRIPT" > "$STAGE175_LOG" 2>&1; then
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: stage175 suite failed" >&2
    echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: log=$STAGE175_LOG" >&2
    exit 8
  fi
  STAGE175_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE175_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE175_SUITE_PACKET" || ! -f "$STAGE175_SUITE_PACKET" ]]; then
  echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: missing stage175 suite packet" >&2
  exit 9
fi
for fact in \
  "stage175_renderer_state_write_rollback_ready_result_suite_passed=true" \
  "renderer_state_write_rollback_ready_result_ready=true" \
  "renderer_state_write_rollback_ready_result_source_ready=true" \
  "renderer_state_write_rollback_ready_result_runtime_admitted=false" \
  "stage176_visibility_not_published_boundary_input_prepared=true" \
  "rollback_ready_result_non_mutating=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE175_SUITE_PACKET" "$fact"
done

stage175_route="$(fact_value "$STAGE175_SUITE_PACKET" "renderer_state_write_rollback_ready_result_route_classification")"
stage175_runtime_admitted="$(fact_value "$STAGE175_SUITE_PACKET" "renderer_state_write_rollback_ready_result_runtime_admitted")"
stage175_runtime_admitted="${stage175_runtime_admitted:-false}"
visibility_route="renderer_state_write_visibility_not_published_boundary_ready_internal_only"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage176_renderer_state_write_visibility_not_published_boundary_packet_version=1"
  echo "stage175_input_mode=$stage175_input_mode"
  echo "stage175_suite_packet=$STAGE175_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage175_log=$STAGE175_LOG"
  echo "stage175_rollback_ready_result_consumed=true"
  echo "stage175_rollback_ready_result_route_classification=$stage175_route"
  echo "stage175_rollback_ready_result_runtime_admitted=$stage175_runtime_admitted"
  echo "renderer_state_write_visibility_not_published_boundary_route_classification=$visibility_route"
  echo "renderer_state_write_visibility_not_published_boundary_ready=true"
  echo "renderer_state_write_visibility_not_published_boundary_source_ready=true"
  echo "renderer_state_write_visibility_not_published_boundary_runtime_admitted=false"
  echo "visibility_not_published_boundary_materialized=true"
  echo "rollback_ready_result_to_visibility_stop_line_bound=true"
  echo "internal_visibility_shadow_only=true"
  echo "stage177_renderer_state_write_first_slice_readiness_decision_input_prepared=true"
  echo "visibility_publication_internal_only=true"
  echo "visibility_published=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage177_renderer_state_write_first_slice_readiness_decision_after_visibility_not_published_boundary"
  echo "stage176_renderer_state_write_visibility_not_published_boundary_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: route_classification=$visibility_route"
echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: renderer_state_write_visibility_not_published_boundary_packet_path=$RESULT_PACKET"
echo "cjgui stage176 renderer-state write visibility-not-published boundary packet: renderer_state_write=false"
