#!/usr/bin/env zsh
#
# Focused suite for stage823. It consumes stage822 and records owner-review
# result surfaces across five demo hosts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE823_TMPDIR:-/private/tmp/cjgui-stage821-stage824/stage823}"
SUITE_PACKET="$TMP_DIR/stage823-commit-first-slice-owner-review-demo-host-surface-suite.packet"
STAGE822_SUITE_PACKET="${CJGUI_STAGE823_INPUT_PACKET:-${CJGUI_STAGE822_COMMIT_FIRST_SLICE_REVIEW_DECISION_ROUTER_SUITE_PACKET:-/private/tmp/cjgui-stage821-stage824/stage822/stage822-commit-first-slice-review-decision-router-suite.packet}}"
STAGE822_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage822_commit_first_slice_review_decision_router_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage823_commit_first_slice_owner_review_demo_host_surface_owner.sh"
OWNER_LOG="$TMP_DIR/stage823-commit-first-slice-owner-review-demo-host-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage823 commit first-slice owner review demo-host surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE822_SUITE_PACKET" ]] || ! grep -F "stage822_commit_first_slice_review_decision_router_suite_passed=true" "$STAGE822_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE822_TMPDIR="$TMP_DIR/stage822" zsh "$STAGE822_SUITE_SCRIPT" >/dev/null
  STAGE822_SUITE_PACKET="$TMP_DIR/stage822/stage822-commit-first-slice-review-decision-router-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage822_commit_first_slice_review_decision_router_consumed=true" \
  "todo_commit_first_slice_owner_review_surface_materialized=true" \
  "settings_commit_first_slice_owner_review_surface_materialized=true" \
  "ai_generated_settings_commit_first_slice_owner_review_surface_materialized=true" \
  "chat_composer_commit_first_slice_owner_review_surface_materialized=true" \
  "file_browser_commit_first_slice_owner_review_surface_materialized=true" \
  "commit_first_slice_owner_review_result_surface_materialized=true" \
  "commit_first_slice_demo_surfaces_bound_to_stage822_decision_router=true" \
  "stage824_commit_first_slice_owner_review_runtime_manager_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage822_commit_first_slice_review_decision_router_suite_passed=true" \
  "commit_first_slice_accept_review_decision_route_materialized=true" \
  "commit_first_slice_commit_candidate_hold_ledger_materialized=true"; do
  require_file_fact "$STAGE822_SUITE_PACKET" "$fact"
done

{
  echo "stage823_commit_first_slice_owner_review_demo_host_surface_suite_version=1"
  echo "stage822_suite_packet=$STAGE822_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage823_commit_first_slice_owner_review_demo_host_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage823 commit first-slice owner review demo-host surface suite: route_classification=commit_owner_review_demo_host_surface"
echo "cjgui stage823 commit first-slice owner review demo-host surface suite: suite_packet_path=$SUITE_PACKET"
