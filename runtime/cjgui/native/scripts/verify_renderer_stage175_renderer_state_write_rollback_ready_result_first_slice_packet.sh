#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage175 rollback-ready result packet，消费
# stage174 commit dry-run suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE175_PACKET_TMPDIR:-/tmp/cjgui-stage175-renderer-state-write-rollback-ready-result-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage175_renderer_state_write_rollback_ready_result_first_slice_owner.sh"
STAGE174_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage174_renderer_state_write_commit_dry_run_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE174_LOG="$TMP_DIR/stage174.log"
RESULT_PACKET="$TMP_DIR/stage175-renderer-state-write-rollback-ready-result-first-slice.packet"
STAGE174_SUITE_PACKET="${CJGUI_STAGE174_RENDERER_STATE_WRITE_COMMIT_DRY_RUN_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage174"
: > "$OWNER_LOG"
: > "$STAGE174_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE174_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage175 renderer-state write rollback-ready result packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage175 renderer-state write rollback-ready result packet: syntax check failed $script" >&2
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
    echo "cjgui stage175 renderer-state write rollback-ready result packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result packet: owner probe failed" >&2
  echo "cjgui stage175 renderer-state write rollback-ready result packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage175_renderer_state_write_rollback_ready_result_owner_present=true" \
  "stage174_renderer_state_write_commit_dry_run_required=true" \
  "rollback_ready_result_envelope_materialized=true" \
  "commit_dry_run_result_to_rollback_readiness_bound=true" \
  "rollback_snapshot_owner_local_only=true" \
  "stage176_visibility_not_published_boundary_input_prepared=true" \
  "rollback_ready_result_non_mutating=true" \
  "visibility_publication_blocked=true" \
  "renderer_state_write_rollback_ready_result_ready=true" \
  "renderer_state_write_rollback_ready_result_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage174_input_mode="generated_stage174_suite_packet"
if [[ -n "$STAGE174_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE174_SUITE_PACKET" ]]; then
    echo "cjgui stage175 renderer-state write rollback-ready result packet: provided stage174 suite packet missing $STAGE174_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage174_suite_packet_used=true" > "$STAGE174_LOG"
  stage174_input_mode="provided_stage174_suite_packet"
else
  if ! env CJGUI_STAGE174_TMPDIR="$TMP_DIR/stage174" zsh "$STAGE174_SUITE_SCRIPT" > "$STAGE174_LOG" 2>&1; then
    echo "cjgui stage175 renderer-state write rollback-ready result packet: stage174 suite failed" >&2
    echo "cjgui stage175 renderer-state write rollback-ready result packet: log=$STAGE174_LOG" >&2
    exit 8
  fi
  STAGE174_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE174_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE174_SUITE_PACKET" || ! -f "$STAGE174_SUITE_PACKET" ]]; then
  echo "cjgui stage175 renderer-state write rollback-ready result packet: missing stage174 suite packet" >&2
  exit 9
fi
for fact in \
  "stage174_renderer_state_write_commit_dry_run_suite_passed=true" \
  "renderer_state_write_commit_dry_run_ready=true" \
  "renderer_state_write_commit_dry_run_source_ready=true" \
  "renderer_state_write_commit_dry_run_runtime_admitted=false" \
  "stage175_rollback_ready_result_input_prepared=true" \
  "commit_dry_run_non_mutating=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE174_SUITE_PACKET" "$fact"
done

stage174_route="$(fact_value "$STAGE174_SUITE_PACKET" "renderer_state_write_commit_dry_run_route_classification")"
stage174_runtime_admitted="$(fact_value "$STAGE174_SUITE_PACKET" "renderer_state_write_commit_dry_run_runtime_admitted")"
stage174_runtime_admitted="${stage174_runtime_admitted:-false}"
rollback_route="renderer_state_write_rollback_ready_result_envelope_ready_non_mutating"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage175 renderer-state write rollback-ready result packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage175_renderer_state_write_rollback_ready_result_packet_version=1"
  echo "stage174_input_mode=$stage174_input_mode"
  echo "stage174_suite_packet=$STAGE174_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage174_log=$STAGE174_LOG"
  echo "stage174_renderer_state_write_commit_dry_run_consumed=true"
  echo "stage174_renderer_state_write_commit_dry_run_route_classification=$stage174_route"
  echo "stage174_renderer_state_write_commit_dry_run_runtime_admitted=$stage174_runtime_admitted"
  echo "renderer_state_write_rollback_ready_result_route_classification=$rollback_route"
  echo "renderer_state_write_rollback_ready_result_ready=true"
  echo "renderer_state_write_rollback_ready_result_source_ready=true"
  echo "renderer_state_write_rollback_ready_result_runtime_admitted=false"
  echo "rollback_ready_result_envelope_materialized=true"
  echo "commit_dry_run_result_to_rollback_readiness_bound=true"
  echo "rollback_snapshot_owner_local_only=true"
  echo "rollback_ready_result_non_mutating=true"
  echo "stage176_visibility_not_published_boundary_input_prepared=true"
  echo "visibility_publication_blocked=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage176_renderer_state_write_visibility_not_published_boundary_after_rollback_ready_result"
  echo "stage175_renderer_state_write_rollback_ready_result_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage175 renderer-state write rollback-ready result packet: route_classification=$rollback_route"
echo "cjgui stage175 renderer-state write rollback-ready result packet: renderer_state_write_rollback_ready_result_packet_path=$RESULT_PACKET"
echo "cjgui stage175 renderer-state write rollback-ready result packet: renderer_state_write=false"
