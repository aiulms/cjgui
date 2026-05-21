#!/usr/bin/env zsh
#
# 维护注释：本脚本生成 stage183 final admission recheck packet，
# 消费 stage182 visibility publication decision suite packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
TMP_DIR="${CJGUI_STAGE183_PACKET_TMPDIR:-/tmp/cjgui-stage183-final-admission-recheck-packet-$$}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage183_renderer_state_write_final_admission_recheck_first_slice_owner.sh"
STAGE182_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage182_renderer_state_write_visibility_publication_decision_first_slice_suite.sh"
OWNER_LOG="$TMP_DIR/owner.log"
STAGE182_LOG="$TMP_DIR/stage182.log"
RESULT_PACKET="$TMP_DIR/stage183-renderer-state-write-final-admission-recheck-first-slice.packet"
STAGE182_SUITE_PACKET="${CJGUI_STAGE182_VISIBILITY_PUBLICATION_DECISION_SUITE_PACKET:-}"

mkdir -p "$TMP_DIR" "$TMP_DIR/stage182"
: > "$OWNER_LOG"
: > "$STAGE182_LOG"
: > "$RESULT_PACKET"

for script in "$OWNER_SCRIPT" "$STAGE182_SUITE_SCRIPT"; do
  if [[ ! -x "$script" ]]; then
    echo "cjgui stage183 final admission recheck packet: missing executable script $script" >&2
    exit 3
  fi
  if ! zsh -n "$script"; then
    echo "cjgui stage183 final admission recheck packet: syntax check failed $script" >&2
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
    echo "cjgui stage183 final admission recheck packet: missing fact $fact in $file" >&2
    exit 5
  fi
}

if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage183 final admission recheck packet: owner probe failed" >&2
  echo "cjgui stage183 final admission recheck packet: log=$OWNER_LOG" >&2
  exit 6
fi
for fact in \
  "stage183_final_admission_recheck_owner_present=true" \
  "stage182_visibility_publication_decision_required=true" \
  "renderer_state_write_final_admission_ledger_materialized=true" \
  "visibility_publication_decision_to_final_admission_bound=true" \
  "production_truth_backend_semantic_predicate_ledger_bound=true" \
  "result_envelope_promotion_token_denial_bound=true" \
  "stage184_renderer_state_write_owner_local_state_envelope_input_prepared=true" \
  "renderer_state_write_final_admission_non_mutating=true" \
  "renderer_state_write_final_admission_denied=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

stage182_input_mode="generated_stage182_suite_packet"
if [[ -n "$STAGE182_SUITE_PACKET" ]]; then
  if [[ ! -f "$STAGE182_SUITE_PACKET" ]]; then
    echo "cjgui stage183 final admission recheck packet: provided stage182 suite packet missing $STAGE182_SUITE_PACKET" >&2
    exit 7
  fi
  echo "provided_stage182_suite_packet_used=true" > "$STAGE182_LOG"
  stage182_input_mode="provided_stage182_suite_packet"
else
  if ! env CJGUI_STAGE182_TMPDIR="$TMP_DIR/stage182" zsh "$STAGE182_SUITE_SCRIPT" > "$STAGE182_LOG" 2>&1; then
    echo "cjgui stage183 final admission recheck packet: stage182 suite failed" >&2
    echo "cjgui stage183 final admission recheck packet: log=$STAGE182_LOG" >&2
    exit 8
  fi
  STAGE182_SUITE_PACKET="$(grep -Eo 'suite_packet_path=[^[:space:]]+' "$STAGE182_LOG" | tail -1 | cut -d= -f2-)"
fi
if [[ -z "$STAGE182_SUITE_PACKET" || ! -f "$STAGE182_SUITE_PACKET" ]]; then
  echo "cjgui stage183 final admission recheck packet: missing stage182 suite packet" >&2
  exit 9
fi
for fact in \
  "stage182_visibility_publication_decision_suite_passed=true" \
  "visibility_publication_decision_ready=true" \
  "visibility_publication_decision_source_ready=true" \
  "visibility_publication_decision_runtime_admitted=false" \
  "visibility_publication_decision_ledger_materialized=true" \
  "visibility_publication_decision_admission_denied=true" \
  "stage183_renderer_state_write_final_admission_recheck_input_prepared=true" \
  "production_render_truth=false" \
  "backend_ready_truth=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE182_SUITE_PACKET" "$fact"
done

stage182_route="$(fact_value "$STAGE182_SUITE_PACKET" "visibility_publication_decision_route_classification")"
stage182_runtime_admitted="$(fact_value "$STAGE182_SUITE_PACKET" "visibility_publication_decision_runtime_admitted")"
stage182_runtime_admitted="${stage182_runtime_admitted:-false}"
final_admission_route="renderer_state_write_final_admission_recheck_ready_admission_denied"

if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage183 final admission recheck packet: protected production bridge/state path modified" >&2
  exit 10
fi

{
  echo "stage183_final_admission_recheck_packet_version=1"
  echo "stage182_input_mode=$stage182_input_mode"
  echo "stage182_suite_packet=$STAGE182_SUITE_PACKET"
  echo "owner_log=$OWNER_LOG"
  echo "stage182_log=$STAGE182_LOG"
  echo "stage182_visibility_publication_decision_consumed=true"
  echo "stage182_visibility_publication_decision_route_classification=$stage182_route"
  echo "stage182_visibility_publication_decision_runtime_admitted=$stage182_runtime_admitted"
  echo "renderer_state_write_final_admission_recheck_route_classification=$final_admission_route"
  echo "renderer_state_write_final_admission_recheck_ready=true"
  echo "renderer_state_write_final_admission_recheck_source_ready=true"
  echo "renderer_state_write_final_admission_recheck_runtime_admitted=false"
  echo "renderer_state_write_final_admission_ledger_materialized=true"
  echo "visibility_publication_decision_to_final_admission_bound=true"
  echo "production_truth_backend_semantic_predicate_ledger_bound=true"
  echo "result_envelope_promotion_token_denial_bound=true"
  echo "renderer_state_write_final_admission_predicates_satisfied=false"
  echo "renderer_state_write_final_admission_non_mutating=true"
  echo "renderer_state_write_final_admission_denied=true"
  echo "stage184_renderer_state_write_owner_local_state_envelope_input_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "semantic_runtime_admission=false"
  echo "result_envelope_promotion_token=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "production_public_c_abi_added=false"
  echo "cjpm_toml_change=false"
  echo "next_route=stage184_renderer_state_write_owner_local_state_envelope_after_final_admission_recheck"
  echo "stage183_final_admission_recheck_packet_passed=true"
} > "$RESULT_PACKET"

echo "cjgui stage183 final admission recheck packet: route_classification=$final_admission_route"
echo "cjgui stage183 final admission recheck packet: final_admission_recheck_packet_path=$RESULT_PACKET"
echo "cjgui stage183 final admission recheck packet: renderer_state_write=false"
