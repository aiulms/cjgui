#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage173 renderer-state write admission readiness
# recheck packet，消费 stage172 visibility admission suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE173_PACKET_TMPDIR:-/tmp/cjgui-stage173-renderer-state-write-admission-readiness-recheck-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage173_renderer_state_write_admission_readiness_recheck_first_slice_owner.sh"
STAGE172_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage172_visibility_publication_admission_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE172_LOG="$TMP_DIR/stage172.log"
RESULT_PACKET="$TMP_DIR/stage173-renderer-state-write-admission-readiness-recheck-first-slice.packet"
STAGE172_SUITE_PACKET="${CJGUI_STAGE172_VISIBILITY_PUBLICATION_ADMISSION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage172"
: > "$OWNER_LOG"
: > "$STAGE172_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE172_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: syntax check failed $script" >&2
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
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage173 renderer-state write admission readiness recheck packet: owner probe failed" >&2
  echo "cjgui stage173 renderer-state write admission readiness recheck packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage173_renderer_state_write_admission_readiness_recheck_owner_present=true" \
  "stage172_visibility_publication_admission_required=true" \
  "renderer_state_write_admission_readiness_ledger_materialized=true" \
  "production_truth_semantic_write_token_predicates_bound=true" \
  "mutation_executor_visibility_rollback_predicates_bound=true" \
  "visibility_publication_admission_to_write_readiness_bound=true" \
  "stage174_renderer_state_write_first_slice_commit_dry_run_input_prepared=true" \
  "renderer_state_write_admission_readiness_recheck_ready=true" \
  "renderer_state_write_admission_readiness_runtime_admitted=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage172_input_mode="generated_stage172_suite_packet"
if [[ -n "$STAGE172_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE172_SUITE_PACKET" ]]; then
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: provided stage172 suite packet missing $STAGE172_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage172_suite_packet_used=true" > "$STAGE172_LOG"
  stage172_input_mode="provided_stage172_suite_packet"
else
  if ! env CJGUI_STAGE172_TMPDIR="$TMP_DIR/stage172" zsh "$STAGE172_SUITE_SCRIPT" > "$STAGE172_LOG" 2>&1; then
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: stage172 suite failed" >&2
    echo "cjgui stage173 renderer-state write admission readiness recheck packet: log=$STAGE172_LOG" >&2
    exit 8
  fi
  STAGE172_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE172_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE172_SUITE_PACKET" || ! -f "$STAGE172_SUITE_PACKET" ]]; then
  echo "cjgui stage173 renderer-state write admission readiness recheck packet: missing stage172 suite packet" >&2
  exit 9
fi
for fact in \
  "stage172_visibility_publication_admission_suite_passed=true" \
  "visibility_publication_admission_ready=true" \
  "visibility_publication_admission_source_ready=true" \
  "visibility_publication_admission_runtime_admitted=false" \
  "stage173_renderer_state_write_admission_readiness_input_prepared=true" \
  "renderer_state_write_execution_blocked=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE172_SUITE_PACKET" "$fact"
done

stage172_route="$(fact_value "$STAGE172_SUITE_PACKET" "visibility_publication_admission_route_classification")"
stage172_runtime_admitted="$(fact_value "$STAGE172_SUITE_PACKET" "visibility_publication_admission_runtime_admitted")"
stage172_runtime_admitted="${stage172_runtime_admitted:-false}"
readiness_route="renderer_state_write_admission_readiness_blocked_visibility_publication_admission"
if [[ "$stage172_route" == *"host_metal_device_unavailable" ]]; then
  readiness_route="renderer_state_write_admission_readiness_blocked_host_metal_device_unavailable"
elif [[ "$stage172_runtime_admitted" == "true" ]]; then
  readiness_route="renderer_state_write_admission_readiness_ready_for_commit_dry_run"
fi

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage173 renderer-state write admission readiness recheck packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage173_renderer_state_write_admission_readiness_recheck_packet_version=1"
  echo "stage172_input_mode=$stage172_input_mode"
  echo "stage172_suite_packet=$STAGE172_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage172_log=$STAGE172_LOG"
  echo "stage172_visibility_publication_admission_consumed=true"
  echo "stage172_visibility_publication_admission_route_classification=$stage172_route"
  echo "stage172_visibility_publication_admission_runtime_admitted=$stage172_runtime_admitted"
  echo "renderer_state_write_admission_readiness_route_classification=$readiness_route"
  echo "renderer_state_write_admission_readiness_recheck_ready=true"
  echo "renderer_state_write_admission_readiness_source_ready=true"
  echo "renderer_state_write_admission_readiness_runtime_admitted=false"
  echo "renderer_state_write_admission_readiness_ledger_materialized=true"
  echo "production_truth_semantic_write_token_predicates_bound=true"
  echo "mutation_executor_visibility_rollback_predicates_bound=true"
  echo "visibility_publication_admission_to_write_readiness_bound=true"
  echo "renderer_state_write_admission_readiness_predicates_satisfied=false"
  echo "stage174_renderer_state_write_first_slice_commit_dry_run_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage174_renderer_state_write_first_slice_commit_dry_run_after_admission_readiness_recheck"
  echo "stage173_renderer_state_write_admission_readiness_recheck_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage173 renderer-state write admission readiness recheck packet: route_classification=$readiness_route"
echo "cjgui stage173 renderer-state write admission readiness recheck packet: renderer_state_write_admission_readiness_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage173 renderer-state write admission readiness recheck packet: renderer_state_write=false"
