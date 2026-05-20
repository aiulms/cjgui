#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage165 visibility publication packet，消费 stage164
# rollback publication suite packet 并输出 write-decision recheck 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE165_PACKET_TMPDIR:-/tmp/cjgui-stage165-renderer-state-write-visibility-publication-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage165_renderer_state_write_visibility_publication_first_slice_owner.sh"
STAGE164_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage164_renderer_state_write_rollback_publication_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE164_LOG="$TMP_DIR/stage164.log"
RESULT_PACKET="$TMP_DIR/stage165-renderer-state-write-visibility-publication-first-slice.packet"
STAGE164_SUITE_PACKET="${CJGUI_STAGE164_RENDERER_STATE_WRITE_ROLLBACK_PUBLICATION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage164"
: > "$OWNER_LOG"
: > "$STAGE164_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE164_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage165 renderer-state write visibility publication packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage165 renderer-state write visibility publication packet: syntax check failed $script" >&2
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
    echo "cjgui stage165 renderer-state write visibility publication packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage165 renderer-state write visibility publication packet: owner probe failed" >&2
  echo "cjgui stage165 renderer-state write visibility publication packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage165_renderer_state_write_visibility_publication_owner_present=true" \
  "stage164_renderer_state_write_rollback_publication_required=true" \
  "renderer_state_write_visibility_publication_result_materialized=true" \
  "renderer_state_write_visibility_publication_internal_only=true" \
  "renderer_state_write_decision_recheck_input_prepared=true" \
  "renderer_state_write_visibility_publication_ready=true" \
  "renderer_state_write_visibility_publication_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage164_input_mode="generated_stage164_suite_packet"
if [[ -n "$STAGE164_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE164_SUITE_PACKET" ]]; then
    echo "cjgui stage165 renderer-state write visibility publication packet: provided stage164 suite packet missing $STAGE164_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage164_suite_packet_used=true" > "$STAGE164_LOG"
  stage164_input_mode="provided_stage164_suite_packet"
else
  if ! env CJGUI_STAGE164_TMPDIR="$TMP_DIR/stage164" zsh "$STAGE164_SUITE_SCRIPT" > "$STAGE164_LOG" 2>&1; then
    echo "cjgui stage165 renderer-state write visibility publication packet: stage164 suite failed" >&2
    echo "cjgui stage165 renderer-state write visibility publication packet: log=$STAGE164_LOG" >&2
    exit 8
  fi
  STAGE164_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE164_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE164_SUITE_PACKET" || ! -f "$STAGE164_SUITE_PACKET" ]]; then
  echo "cjgui stage165 renderer-state write visibility publication packet: missing stage164 suite packet" >&2
  exit 9
fi
for fact in \
  "stage164_renderer_state_write_rollback_publication_suite_passed=true" \
  "renderer_state_write_rollback_publication_ready=true" \
  "renderer_state_write_rollback_publication_source_ready=true" \
  "renderer_state_write_rollback_publication_runtime_admitted=false" \
  "renderer_state_write_visibility_publication_result_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE164_SUITE_PACKET" "$fact"
done

stage164_route="$(fact_value "$STAGE164_SUITE_PACKET" "renderer_state_write_rollback_publication_route_classification")"
stage164_runtime_admitted="$(fact_value "$STAGE164_SUITE_PACKET" "renderer_state_write_rollback_publication_runtime_admitted")"
stage164_runtime_admitted="${stage164_runtime_admitted:-false}"
visibility_route="renderer_state_write_visibility_publication_blocked_stage164_runtime_admission"
if [[ "$stage164_route" == *"host_metal_device_unavailable" ]]; then
  visibility_route="renderer_state_write_visibility_publication_blocked_host_metal_device_unavailable"
elif [[ "$stage164_runtime_admitted" == "true" ]]; then
  visibility_route="renderer_state_write_visibility_publication_ready_for_write_decision_recheck"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage165 renderer-state write visibility publication packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage165_renderer_state_write_visibility_publication_packet_version=1"
  echo "stage164_input_mode=$stage164_input_mode"
  echo "stage164_suite_packet=$STAGE164_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage164_log=$STAGE164_LOG"
  echo "stage164_renderer_state_write_rollback_publication_consumed=true"
  echo "stage164_renderer_state_write_rollback_publication_route_classification=$stage164_route"
  echo "stage164_renderer_state_write_rollback_publication_runtime_admitted=$stage164_runtime_admitted"
  echo "renderer_state_write_visibility_publication_route_classification=$visibility_route"
  echo "renderer_state_write_visibility_publication_ready=true"
  echo "renderer_state_write_visibility_publication_source_ready=true"
  echo "renderer_state_write_visibility_publication_runtime_admitted=false"
  echo "renderer_state_write_visibility_publication_result_materialized=true"
  echo "renderer_state_write_visibility_publication_internal_only=true"
  echo "renderer_state_write_decision_recheck_input_prepared=true"
  echo "renderer_state_write_visibility_publication_non_mutating=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage166_renderer_state_write_decision_recheck_first_slice_after_visibility_publication"
  echo "stage165_renderer_state_write_visibility_publication_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage165 renderer-state write visibility publication packet: route_classification=$visibility_route"
echo "cjgui stage165 renderer-state write visibility publication packet: renderer_state_write_visibility_publication_packet_path=$RESULT_PACKET"
echo "cjgui stage165 renderer-state write visibility publication packet: renderer_state_write=false"
