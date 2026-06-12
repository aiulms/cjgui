#!/usr/bin/env zsh
#
# Focused suite for stage831. It consumes stage830 and records a non-publishing
# commit candidate with rollback and conflict preflight receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE831_TMPDIR:-/private/tmp/cjgui-stage829-stage832/stage831}"
SUITE_PACKET="$TMP_DIR/stage831-component-state-store-commit-candidate-rollback-snapshot-suite.packet"
STAGE830_SUITE_PACKET="${CJGUI_STAGE831_INPUT_PACKET:-${CJGUI_STAGE830_COMPONENT_STATE_STORE_SLOT_VALUE_MODEL_SUITE_PACKET:-/private/tmp/cjgui-stage829-stage832/stage830/stage830-component-state-store-slot-value-model-suite.packet}}"
STAGE830_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage831-component-state-store-commit-candidate-rollback-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage831 component state-store commit candidate rollback snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE830_SUITE_PACKET" ]] || ! grep -F "stage830_component_state_store_slot_value_model_suite_passed=true" "$STAGE830_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE830_TMPDIR="$TMP_DIR/stage830" zsh "$STAGE830_SUITE_SCRIPT" >/dev/null
  STAGE830_SUITE_PACKET="$TMP_DIR/stage830/stage830-component-state-store-slot-value-model-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage829_component_state_store_publishable_state_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage830_component_state_store_slot_value_model_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage831_component_state_store_commit_candidate_rollback_snapshot_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage830_component_state_store_slot_value_model_consumed=true" \
  "stage829_component_state_store_publishable_state_model_consumed_transitively=true" \
  "owner_local_commit_candidate_materialized=true" \
  "write_set_preflight_ledger_materialized=true" \
  "rollback_snapshot_materialized=true" \
  "conflict_preflight_receipt_materialized=true" \
  "not_published_commit_receipt_materialized=true" \
  "commit_candidate_bound_to_stage830_slot_value_model=true" \
  "stage832_component_state_store_publishable_runtime_manager_prepared=true" \
  "state_store_commit_published=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage830_component_state_store_slot_value_model_suite_passed=true" \
  "component_slot_value_model_materialized=true" \
  "stage831_component_state_store_commit_candidate_rollback_snapshot_prepared=true"; do
  require_file_fact "$STAGE830_SUITE_PACKET" "$fact"
done

{
  echo "stage831_component_state_store_commit_candidate_rollback_snapshot_suite_version=1"
  echo "stage830_suite_packet=$STAGE830_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage832_component_state_store_publishable_runtime_manager_after_stage831"
  echo "stage831_component_state_store_commit_candidate_rollback_snapshot_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage831 component state-store commit candidate rollback snapshot suite: route_classification=commit_candidate_rollback_snapshot"
echo "cjgui stage831 component state-store commit candidate rollback snapshot suite: suite_packet_path=$SUITE_PACKET"
