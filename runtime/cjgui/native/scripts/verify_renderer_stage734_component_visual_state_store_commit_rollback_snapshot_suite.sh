#!/usr/bin/env zsh
#
# Focused suite for stage734. It consumes stage733 and verifies rollback
# snapshot / conflict classifier dry-run facts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE734_TMPDIR:-/private/tmp/cjgui-stage733-stage736/stage734}"
SUITE_PACKET="$TMP_DIR/stage734-component-visual-state-store-commit-rollback-snapshot-suite.packet"
STAGE733_SUITE_PACKET="${CJGUI_STAGE734_INPUT_PACKET:-${CJGUI_STAGE733_COMPONENT_VISUAL_STATE_STORE_COMMIT_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage733-stage736/stage733/stage733-component-visual-state-store-commit-preflight-suite.packet}}"
STAGE733_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage733_component_visual_state_store_commit_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage734_component_visual_state_store_commit_rollback_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage734-component-visual-state-store-commit-rollback-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage734 component visual state store commit rollback snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE733_SUITE_PACKET" ]] || ! grep -F "stage733_component_visual_state_store_commit_preflight_suite_passed=true" "$STAGE733_SUITE_PACKET" >/dev/null 2>&1; then
  zsh "$STAGE733_SUITE_SCRIPT" >/dev/null
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage733_component_visual_state_store_commit_preflight_consumed=true" \
  "commit_rollback_base_snapshot_materialized=true" \
  "pending_commit_snapshot_materialized=true" \
  "validation_failure_rollback_branch_materialized=true" \
  "owner_reject_rollback_branch_materialized=true" \
  "commit_conflict_classifier_materialized=true" \
  "stage735_component_visual_state_store_commit_host_inspection_ui_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage733_component_visual_state_store_commit_preflight_suite_version=1" \
  "shared_component_visual_state_store_commit_preflight_materialized=true" \
  "owner_local_commit_candidate_ledger_materialized=true" \
  "stage734_component_visual_state_store_commit_rollback_snapshot_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE733_SUITE_PACKET" "$fact"
done

{
  echo "stage734_component_visual_state_store_commit_rollback_snapshot_suite_version=1"
  echo "stage733_component_visual_state_store_commit_preflight_suite_packet=$STAGE733_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage735_component_visual_state_store_commit_host_inspection_ui_after_stage734"
  echo "stage734_component_visual_state_store_commit_rollback_snapshot_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage734 component visual state store commit rollback snapshot suite: route_classification=component_visual_state_store_commit_rollback_snapshot_ready"
echo "cjgui stage734 component visual state store commit rollback snapshot suite: suite_packet_path=$SUITE_PACKET"
