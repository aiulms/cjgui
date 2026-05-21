#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage174 renderer-state write commit dry-run
# packet，消费 stage173 admission readiness recheck suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE174_PACKET_TMPDIR:-/tmp/cjgui-stage174-renderer-state-write-commit-dry-run-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage174_renderer_state_write_commit_dry_run_first_slice_owner.sh"
STAGE173_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage173_renderer_state_write_admission_readiness_recheck_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE173_LOG="$TMP_DIR/stage173.log"
RESULT_PACKET="$TMP_DIR/stage174-renderer-state-write-commit-dry-run-first-slice.packet"
STAGE173_SUITE_PACKET="${CJGUI_STAGE173_RENDERER_STATE_WRITE_ADMISSION_READINESS_RECHECK_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage173"
: > "$OWNER_LOG"
: > "$STAGE173_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE173_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage174 renderer-state write commit dry-run packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage174 renderer-state write commit dry-run packet: syntax check failed $script" >&2
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
    echo "cjgui stage174 renderer-state write commit dry-run packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage174 renderer-state write commit dry-run packet: owner probe failed" >&2
  echo "cjgui stage174 renderer-state write commit dry-run packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage174_renderer_state_write_commit_dry_run_owner_present=true" \
  "stage173_renderer_state_write_admission_readiness_recheck_required=true" \
  "renderer_state_write_commit_dry_run_envelope_materialized=true" \
  "write_admission_ledger_to_commit_dry_run_bound=true" \
  "owner_local_renderer_state_candidate_bound=true" \
  "stage175_rollback_ready_result_input_prepared=true" \
  "commit_dry_run_non_mutating=true" \
  "visibility_not_published=true" \
  "renderer_state_write_commit_dry_run_ready=true" \
  "renderer_state_write_commit_dry_run_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage173_input_mode="generated_stage173_suite_packet"
if [[ -n "$STAGE173_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE173_SUITE_PACKET" ]]; then
    echo "cjgui stage174 renderer-state write commit dry-run packet: provided stage173 suite packet missing $STAGE173_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage173_suite_packet_used=true" > "$STAGE173_LOG"
  stage173_input_mode="provided_stage173_suite_packet"
else
  if ! env CJGUI_STAGE173_TMPDIR="$TMP_DIR/stage173" zsh "$STAGE173_SUITE_SCRIPT" > "$STAGE173_LOG" 2>&1; then
    echo "cjgui stage174 renderer-state write commit dry-run packet: stage173 suite failed" >&2
    echo "cjgui stage174 renderer-state write commit dry-run packet: log=$STAGE173_LOG" >&2
    exit 8
  fi
  STAGE173_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE173_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE173_SUITE_PACKET" || ! -f "$STAGE173_SUITE_PACKET" ]]; then
  echo "cjgui stage174 renderer-state write commit dry-run packet: missing stage173 suite packet" >&2
  exit 9
fi
for fact in \
  "stage173_renderer_state_write_admission_readiness_recheck_suite_passed=true" \
  "renderer_state_write_admission_readiness_recheck_ready=true" \
  "renderer_state_write_admission_readiness_source_ready=true" \
  "renderer_state_write_admission_readiness_runtime_admitted=false" \
  "stage174_renderer_state_write_first_slice_commit_dry_run_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE173_SUITE_PACKET" "$fact"
done

stage173_route="$(fact_value "$STAGE173_SUITE_PACKET" "renderer_state_write_admission_readiness_route_classification")"
stage173_runtime_admitted="$(fact_value "$STAGE173_SUITE_PACKET" "renderer_state_write_admission_readiness_runtime_admitted")"
stage173_runtime_admitted="${stage173_runtime_admitted:-false}"
commit_route="renderer_state_write_commit_dry_run_envelope_ready_non_mutating"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage174 renderer-state write commit dry-run packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage174_renderer_state_write_commit_dry_run_packet_version=1"
  echo "stage173_input_mode=$stage173_input_mode"
  echo "stage173_suite_packet=$STAGE173_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage173_log=$STAGE173_LOG"
  echo "stage173_renderer_state_write_admission_readiness_recheck_consumed=true"
  echo "stage173_renderer_state_write_admission_readiness_route_classification=$stage173_route"
  echo "stage173_renderer_state_write_admission_readiness_runtime_admitted=$stage173_runtime_admitted"
  echo "renderer_state_write_commit_dry_run_route_classification=$commit_route"
  echo "renderer_state_write_commit_dry_run_ready=true"
  echo "renderer_state_write_commit_dry_run_source_ready=true"
  echo "renderer_state_write_commit_dry_run_runtime_admitted=false"
  echo "renderer_state_write_commit_dry_run_envelope_materialized=true"
  echo "write_admission_ledger_to_commit_dry_run_bound=true"
  echo "owner_local_renderer_state_candidate_bound=true"
  echo "commit_dry_run_non_mutating=true"
  echo "stage175_rollback_ready_result_input_prepared=true"
  echo "visibility_published=false"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage175_renderer_state_write_rollback_ready_result_after_commit_dry_run"
  echo "stage174_renderer_state_write_commit_dry_run_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage174 renderer-state write commit dry-run packet: route_classification=$commit_route"
echo "cjgui stage174 renderer-state write commit dry-run packet: renderer_state_write_commit_dry_run_packet_path=$RESULT_PACKET"
echo "cjgui stage174 renderer-state write commit dry-run packet: renderer_state_write=false"
