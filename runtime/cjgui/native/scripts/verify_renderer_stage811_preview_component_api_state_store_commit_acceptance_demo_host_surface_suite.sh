#!/usr/bin/env zsh
#
# Focused suite for stage811. It consumes stage810 and records demo-host acceptance rehearsal surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE811_TMPDIR:-/private/tmp/cjgui-stage809-stage812/stage811}"
SUITE_PACKET="$TMP_DIR/stage811-preview-component-api-state-store-commit-acceptance-demo-host-surface-suite.packet"
STAGE810_SUITE_PACKET="${CJGUI_STAGE811_INPUT_PACKET:-${CJGUI_STAGE810_PREVIEW_COMPONENT_API_STATE_STORE_COMMIT_ACCEPTANCE_DECISION_DRY_RUN_SUITE_PACKET:-/private/tmp/cjgui-stage809-stage812/stage810/stage810-preview-component-api-state-store-commit-acceptance-decision-dry-run-suite.packet}}"
STAGE810_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage811-preview-component-api-state-store-commit-acceptance-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage811 preview component api state-store commit acceptance demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE810_SUITE_PACKET" ]] || ! grep -F "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite_passed=true" "$STAGE810_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE810_TMPDIR="$TMP_DIR/stage810" zsh "$STAGE810_SUITE_SCRIPT" >/dev/null
  STAGE810_SUITE_PACKET="$TMP_DIR/stage810/stage810-preview-component-api-state-store-commit-acceptance-decision-dry-run-suite.packet"
fi

for script in \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage809_preview_component_api_state_store_commit_acceptance_rehearsal_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite.sh" \
  "$SCRIPT_DIR/verify_renderer_stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_owner.sh" \
  "$SCRIPT_DIR/verify_renderer_stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_suite.sh"; do
  zsh -n "$script"
done

zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_consumed=true" \
  "acceptance_inspection_rows_materialized=true" \
  "decision_result_surface_refresh_materialized=true" \
  "todo_acceptance_preview_surface_materialized=true" \
  "settings_acceptance_preview_surface_materialized=true" \
  "ai_generated_settings_acceptance_preview_surface_materialized=true" \
  "chat_composer_acceptance_preview_surface_materialized=true" \
  "file_browser_acceptance_preview_surface_materialized=true" \
  "acceptance_demo_host_surface_bound_to_stage810_decision_dry_run=true" \
  "acceptance_demo_host_surface_non_committing=true" \
  "stage812_preview_component_api_state_store_commit_acceptance_runtime_manager_prepared=true" \
  "preview_component_api_commit_committed=false" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite_passed=true" \
  "compatibility_boundary_receipt_materialized=true" \
  "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_prepared=true"; do
  require_file_fact "$STAGE810_SUITE_PACKET" "$fact"
done

{
  echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_suite_version=1"
  echo "stage810_preview_component_api_state_store_commit_acceptance_decision_dry_run_suite_packet=$STAGE810_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage811_preview_component_api_state_store_commit_acceptance_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage811 preview component api state-store commit acceptance demo-host surface suite: route_classification=state_store_commit_acceptance_demo_host_surface"
echo "cjgui stage811 preview component api state-store commit acceptance demo-host surface suite: suite_packet_path=$SUITE_PACKET"
