#!/usr/bin/env zsh
#
# Focused suite for stage883. It consumes stage882 and records five demo-host
# accepted commit inspection surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE883_TMPDIR:-/private/tmp/cjgui-stage881-stage884/stage883}"
SUITE_PACKET="$TMP_DIR/stage883-owner-local-accepted-commit-demo-surface-suite.packet"
STAGE882_SUITE_PACKET="${CJGUI_STAGE883_INPUT_PACKET:-${CJGUI_STAGE882_OWNER_LOCAL_ACCEPTED_COMMIT_APPLICATION_PLAN_SUITE_PACKET:-/private/tmp/cjgui-stage881-stage884/stage882/stage882-owner-local-accepted-commit-application-plan-suite.packet}}"
STAGE882_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage882_owner_local_accepted_commit_application_plan_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage883_owner_local_accepted_commit_demo_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage883-owner-local-accepted-commit-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage883 owner-local accepted commit demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE882_SUITE_PACKET" ]] || ! grep -F "stage882_owner_local_accepted_commit_application_plan_suite_passed=true" "$STAGE882_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE882_TMPDIR="$TMP_DIR/stage882" zsh "$STAGE882_SUITE_SCRIPT" >/dev/null
  STAGE882_SUITE_PACKET="$TMP_DIR/stage882/stage882-owner-local-accepted-commit-application-plan-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage882_owner_local_accepted_commit_application_plan_suite_passed=true" \
  "stage883_owner_local_accepted_commit_demo_surface_prepared=true" \
  "accepted_commit_not_published_receipt_materialized=true" \
  "state_store_write_preview_boundary_materialized=true"; do
  require_file_fact "$STAGE882_SUITE_PACKET" "$fact"
done

for fact in \
  "stage882_owner_local_accepted_commit_application_plan_consumed=true" \
  "todo_owner_local_accepted_commit_surface_materialized=true" \
  "settings_owner_local_accepted_commit_surface_materialized=true" \
  "ai_generated_settings_owner_local_accepted_commit_surface_materialized=true" \
  "chat_composer_owner_local_accepted_commit_surface_materialized=true" \
  "file_browser_owner_local_accepted_commit_surface_materialized=true" \
  "accepted_commit_application_inspection_rows_materialized=true" \
  "accepted_commit_rollback_token_rows_materialized=true" \
  "accepted_commit_not_published_receipt_rows_materialized=true" \
  "accepted_commit_surface_bound_to_application_plan=true" \
  "stage884_owner_local_accepted_commit_runtime_manager_prepared=true" \
  "state_store_write_executed=false" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage883_owner_local_accepted_commit_demo_surface_suite_version=1"
  echo "stage882_suite_packet=$STAGE882_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage884_owner_local_accepted_commit_runtime_manager_after_stage883"
  echo "stage883_owner_local_accepted_commit_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage883 owner-local accepted commit demo surface suite: route_classification=accepted_commit_demo_surface"
echo "cjgui stage883 owner-local accepted commit demo surface suite: suite_packet_path=$SUITE_PACKET"
