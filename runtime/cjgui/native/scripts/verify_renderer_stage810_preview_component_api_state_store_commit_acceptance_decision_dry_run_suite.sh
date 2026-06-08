#!/usr/bin/env zsh
#
# Focused suite for stage810. It consumes stage809 and records non-dispatching acceptance decisions.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE810_TMPDIR:-/private/tmp/cjgui-stage809-stage812/stage810}"
SUITE_PACKET="$TMP_DIR/stage810-preview-component-api-state-store-commit-acceptance-decision-dry-run-suite.packet"
STAGE809_SUITE_PACKET="${CJGUI_STAGE810_INPUT_PACKET:-${CJGUI_STAGE809_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_ACCEPTANCE_REHEARSAL_SUITE_PACKET:-/private/tmp/cjgui-stage809-stage812/stage809/stage809-preview-component-api-state-store-commit-acceptance-rehearsal-suite.packet}}"
STAGE809_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_owner.sh"
OWNER_LOG="$TMP_DIR/stage810-preview-component-api-state-store-commit-acceptance-decision-dry-run-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage810 preview component api state-store commit acceptance decision dry-run suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE809_SUITE_PACKET" ]] || ! grep -F "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite_passed=true" "$STAGE809_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE809_TMPDIR="$TMP_DIR/stage809" zsh "$STAGE809_SUITE_SCRIPT" >/dev/null
  STAGE809_SUITE_PACKET="$TMP_DIR/stage809/stage809-preview-component-api-state-store-commit-acceptance-rehearsal-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_consumed=true" \
  "accept_decision_dry_run_materialized=true" \
  "reject_decision_dry_run_materialized=true" \
  "request_changes_decision_dry_run_materialized=true" \
  "compatibility_boundary_receipt_materialized=true" \
  "acceptance_blocker_reason_ledger_materialized=true" \
  "reviewer_decision_note_materialized=true" \
  "acceptance_decision_dry_run_non_dispatching=true" \
  "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite_passed=true" \
  "acceptance_rehearsal_plan_materialized=true" \
  "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_prepared=true"; do
  require_file_fact "$STAGE809_SUITE_PACKET" "$fact"
done

{
  echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite_version=1"
  echo "stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite_packet=$STAGE809_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage810 preview component api state-store commit acceptance decision dry-run suite: route_classification=state_store_commit_acceptance_decision_dry_run"
echo "cjgui stage810 preview component api state-store commit acceptance decision dry-run suite: suite_packet_path=$SUITE_PACKET"
