#!/usr/bin/env zsh
#
# Focused suite for stage733. It consumes stage732 and verifies the shared
# component visual state store commit preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE733_TMPDIR:-/private/tmp/cjgui-stage733-stage736/stage733}"
SUITE_PACKET="$TMP_DIR/stage733-component-visual-state-store-commit-preflight-suite.packet"
STAGE732_OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage732_component_visual_state_store_resolver_runtime_manager_owner.sh"
STAGE732_OWNER_LOG="$TMP_DIR/stage732-component-visual-state-store-resolver-runtime-manager-owner.log"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage733_component_visual_state_store_commit_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage733-component-visual-state-store-commit-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage733 component visual state store commit preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$STAGE732_OWNER_SCRIPT"
zsh "$STAGE732_OWNER_SCRIPT" > "$STAGE732_OWNER_LOG" 2>&1
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage732_component_visual_state_store_resolver_runtime_manager_consumed=true" \
  "shared_component_visual_state_store_commit_preflight_materialized=true" \
  "owner_local_commit_candidate_ledger_materialized=true" \
  "commit_validation_gate_materialized=true" \
  "resolver_result_to_commit_plan_bridge_materialized=true" \
  "stage734_component_visual_state_store_commit_rollback_snapshot_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage732_component_visual_state_store_resolver_runtime_manager_owner_present=true" \
  "shared_visual_state_store_resolver_runtime_manager_materialized=true" \
  "visual_state_store_resolver_execution_receipt_contract_materialized=true" \
  "stage733_component_visual_state_store_commit_preflight_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE732_OWNER_LOG" "$fact"
done

{
  echo "stage733_component_visual_state_store_commit_preflight_suite_version=1"
  echo "stage732_component_visual_state_store_resolver_runtime_manager_owner_log=$STAGE732_OWNER_LOG"
  cat "$OWNER_LOG"
  echo "next_route=stage734_component_visual_state_store_commit_rollback_snapshot_after_stage733"
  echo "stage733_component_visual_state_store_commit_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage733 component visual state store commit preflight suite: route_classification=component_visual_state_store_commit_preflight_ready"
echo "cjgui stage733 component visual state store commit preflight suite: suite_packet_path=$SUITE_PACKET"
