#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage182 visibility publication decision packet，
# 消费 stage181 visibility publication readiness bridge suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE182_PACKET_TMPDIR:-/tmp/cjgui-stage182-visibility-publication-decision-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage182_renderer_state_write_visibility_publication_decision_first_slice_owner.sh"
STAGE181_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage181_visibility_publication_readiness_bridge_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE181_LOG="$TMP_DIR/stage181.log"
RESULT_PACKET="$TMP_DIR/stage182-renderer-state-write-visibility-publication-decision-first-slice.packet"
STAGE181_SUITE_PACKET="${CJGUI_STAGE181_VISIBILITY_PUBLICATION_READINESS_BRIDGE_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage181"
: > "$OWNER_LOG"
: > "$STAGE181_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE181_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage182 visibility publication decision packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage182 visibility publication decision packet: syntax check failed $script" >&2
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
    echo "cjgui stage182 visibility publication decision packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage182 visibility publication decision packet: owner probe failed" >&2
  echo "cjgui stage182 visibility publication decision packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage182_visibility_publication_decision_owner_present=true" \
  "stage181_visibility_publication_readiness_bridge_required=true" \
  "visibility_publication_decision_ledger_materialized=true" \
  "visibility_publication_predicate_ledger_to_decision_bound=true" \
  "visibility_publication_admission_denial_bound=true" \
  "stage183_renderer_state_write_final_admission_recheck_input_prepared=true" \
  "visibility_publication_decision_non_mutating=true" \
  "visibility_publication_decision_admission_denied=true" \
  "visibility_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage181_input_mode="generated_stage181_suite_packet"
if [[ -n "$STAGE181_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE181_SUITE_PACKET" ]]; then
    echo "cjgui stage182 visibility publication decision packet: provided stage181 suite packet missing $STAGE181_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage181_suite_packet_used=true" > "$STAGE181_LOG"
  stage181_input_mode="provided_stage181_suite_packet"
else
  if ! env CJGUI_STAGE181_TMPDIR="$TMP_DIR/stage181" zsh "$STAGE181_SUITE_SCRIPT" > "$STAGE181_LOG" 2>&1; then
    echo "cjgui stage182 visibility publication decision packet: stage181 suite failed" >&2
    echo "cjgui stage182 visibility publication decision packet: log=$STAGE181_LOG" >&2
    exit 8
  fi
  STAGE181_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE181_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE181_SUITE_PACKET" || ! -f "$STAGE181_SUITE_PACKET" ]]; then
  echo "cjgui stage182 visibility publication decision packet: missing stage181 suite packet" >&2
  exit 9
fi
for fact in \
  "stage181_visibility_publication_readiness_bridge_suite_passed=true" \
  "visibility_publication_readiness_bridge_ready=true" \
  "visibility_publication_readiness_bridge_source_ready=true" \
  "visibility_publication_readiness_bridge_runtime_admitted=false" \
  "visibility_publication_predicate_ledger_materialized=true" \
  "visibility_publication_admitted=false" \
  "visibility_published=false" \
  "stage182_renderer_state_write_visibility_publication_decision_input_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE181_SUITE_PACKET" "$fact"
done

stage181_route="$(fact_value "$STAGE181_SUITE_PACKET" "visibility_publication_readiness_bridge_route_classification")"
stage181_runtime_admitted="$(fact_value "$STAGE181_SUITE_PACKET" "visibility_publication_readiness_bridge_runtime_admitted")"
stage181_runtime_admitted="${stage181_runtime_admitted:-false}"
decision_route="visibility_publication_decision_ready_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage182 visibility publication decision packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage182_visibility_publication_decision_packet_version=1"
  echo "stage181_input_mode=$stage181_input_mode"
  echo "stage181_suite_packet=$STAGE181_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage181_log=$STAGE181_LOG"
  echo "stage181_visibility_publication_readiness_bridge_consumed=true"
  echo "stage181_visibility_publication_readiness_bridge_route_classification=$stage181_route"
  echo "stage181_visibility_publication_readiness_bridge_runtime_admitted=$stage181_runtime_admitted"
  echo "visibility_publication_decision_route_classification=$decision_route"
  echo "visibility_publication_decision_ready=true"
  echo "visibility_publication_decision_source_ready=true"
  echo "visibility_publication_decision_runtime_admitted=false"
  echo "visibility_publication_decision_ledger_materialized=true"
  echo "visibility_publication_predicate_ledger_to_decision_bound=true"
  echo "visibility_publication_admission_denial_bound=true"
  echo "visibility_publication_decision_predicates_satisfied=false"
  echo "visibility_publication_decision_non_mutating=true"
  echo "visibility_publication_decision_admission_denied=true"
  echo "visibility_published=false"
  echo "stage183_renderer_state_write_final_admission_recheck_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage183_renderer_state_write_final_admission_recheck_after_visibility_publication_decision"
  echo "stage182_visibility_publication_decision_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage182 visibility publication decision packet: route_classification=$decision_route"
echo "cjgui stage182 visibility publication decision packet: visibility_publication_decision_packet_path=$RESULT_PACKET"
echo "cjgui stage182 visibility publication decision packet: renderer_state_write=false"
