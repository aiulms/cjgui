#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage181 visibility publication readiness bridge packet，
# 消费 stage180 guarded executor runtime preflight suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE181_PACKET_TMPDIR:-/tmp/cjgui-stage181-visibility-publication-readiness-bridge-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage181_visibility_publication_readiness_bridge_first_slice_owner.sh"
STAGE180_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage180_guarded_executor_runtime_preflight_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE180_LOG="$TMP_DIR/stage180.log"
RESULT_PACKET="$TMP_DIR/stage181-visibility-publication-readiness-bridge-first-slice.packet"
STAGE180_SUITE_PACKET="${CJGUI_STAGE180_GUARDED_EXECUTOR_RUNTIME_PREFLIGHT_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage180"
: > "$OWNER_LOG"
: > "$STAGE180_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE180_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage181 visibility publication readiness bridge packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage181 visibility publication readiness bridge packet: syntax check failed $script" >&2
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
    echo "cjgui stage181 visibility publication readiness bridge packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage181 visibility publication readiness bridge packet: owner probe failed" >&2
  echo "cjgui stage181 visibility publication readiness bridge packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage181_visibility_publication_readiness_bridge_owner_present=true" \
  "stage180_guarded_executor_runtime_preflight_required=true" \
  "visibility_publication_readiness_bridge_envelope_materialized=true" \
  "guarded_executor_preflight_to_visibility_publication_bound=true" \
  "visibility_publication_predicate_ledger_materialized=true" \
  "visibility_publication_hold_to_rollback_bound=true" \
  "stage182_renderer_state_write_visibility_publication_decision_input_prepared=true" \
  "visibility_publication_readiness_bridge_internal_only=true" \
  "visibility_publication_admission_denied=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage180_input_mode="generated_stage180_suite_packet"
if [[ -n "$STAGE180_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE180_SUITE_PACKET" ]]; then
    echo "cjgui stage181 visibility publication readiness bridge packet: provided stage180 suite packet missing $STAGE180_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage180_suite_packet_used=true" > "$STAGE180_LOG"
  stage180_input_mode="provided_stage180_suite_packet"
else
  if ! env CJGUI_STAGE180_TMPDIR="$TMP_DIR/stage180" zsh "$STAGE180_SUITE_SCRIPT" > "$STAGE180_LOG" 2>&1; then
    echo "cjgui stage181 visibility publication readiness bridge packet: stage180 suite failed" >&2
    echo "cjgui stage181 visibility publication readiness bridge packet: log=$STAGE180_LOG" >&2
    exit 8
  fi
  STAGE180_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE180_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE180_SUITE_PACKET" || ! -f "$STAGE180_SUITE_PACKET" ]]; then
  echo "cjgui stage181 visibility publication readiness bridge packet: missing stage180 suite packet" >&2
  exit 9
fi
for fact in \
  "stage180_guarded_executor_runtime_preflight_suite_passed=true" \
  "guarded_executor_runtime_preflight_ready=true" \
  "guarded_executor_runtime_preflight_source_ready=true" \
  "guarded_executor_runtime_preflight_runtime_admitted=false" \
  "guarded_executor_predicate_recheck_materialized=true" \
  "rollback_visibility_hold_bound=true" \
  "stage181_visibility_publication_readiness_bridge_input_prepared=true" \
  "guarded_executor_runtime_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE180_SUITE_PACKET" "$fact"
done

stage180_route="$(fact_value "$STAGE180_SUITE_PACKET" "guarded_executor_runtime_preflight_route_classification")"
stage180_runtime_admitted="$(fact_value "$STAGE180_SUITE_PACKET" "guarded_executor_runtime_preflight_runtime_admitted")"
stage180_runtime_admitted="${stage180_runtime_admitted:-false}"
publication_route="visibility_publication_readiness_bridge_ready_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage181 visibility publication readiness bridge packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage181_visibility_publication_readiness_bridge_packet_version=1"
  echo "stage180_input_mode=$stage180_input_mode"
  echo "stage180_suite_packet=$STAGE180_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage180_log=$STAGE180_LOG"
  echo "stage180_guarded_executor_runtime_preflight_consumed=true"
  echo "stage180_guarded_executor_runtime_preflight_route_classification=$stage180_route"
  echo "stage180_guarded_executor_runtime_preflight_runtime_admitted=$stage180_runtime_admitted"
  echo "visibility_publication_readiness_bridge_route_classification=$publication_route"
  echo "visibility_publication_readiness_bridge_ready=true"
  echo "visibility_publication_readiness_bridge_source_ready=true"
  echo "visibility_publication_readiness_bridge_runtime_admitted=false"
  echo "visibility_publication_readiness_bridge_envelope_materialized=true"
  echo "guarded_executor_preflight_to_visibility_publication_bound=true"
  echo "visibility_publication_predicate_ledger_materialized=true"
  echo "visibility_publication_hold_to_rollback_bound=true"
  echo "visibility_publication_readiness_bridge_internal_only=true"
  echo "visibility_publication_admitted=false"
  echo "visibility_publication_admission_denied=true"
  echo "visibility_published=false"
  echo "stage182_renderer_state_write_visibility_publication_decision_input_prepared=true"
  echo "renderer_state_write_execution_blocked=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage182_renderer_state_write_visibility_publication_decision_after_readiness_bridge"
  echo "stage181_visibility_publication_readiness_bridge_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage181 visibility publication readiness bridge packet: route_classification=$publication_route"
echo "cjgui stage181 visibility publication readiness bridge packet: visibility_publication_readiness_bridge_packet_path=$RESULT_PACKET"
echo "cjgui stage181 visibility publication readiness bridge packet: renderer_state_write=false"
