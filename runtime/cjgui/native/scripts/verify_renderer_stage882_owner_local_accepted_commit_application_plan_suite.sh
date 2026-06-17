#!/usr/bin/env zsh
#
# Focused suite for stage882. It consumes stage881 and records an owner-local
# accepted commit application plan with rollback and not-published receipt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE882_TMPDIR:-/private/tmp/cjgui-stage881-stage884/stage882}"
SUITE_PACKET="$TMP_DIR/stage882-owner-local-accepted-commit-application-plan-suite.packet"
STAGE881_SUITE_PACKET="${CJGUI_STAGE882_INPUT_PACKET:-${CJGUI_STAGE881_OWNER_LOCAL_ACCEPTED_COMMIT_INSPECTION_SUITE_PACKET:-/private/tmp/cjgui-stage881-stage884/stage881/stage881-owner-local-accepted-commit-inspection-suite.packet}}"
STAGE881_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage881_owner_local_accepted_commit_inspection_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage882_owner_local_accepted_commit_application_plan_owner.sh"
OWNER_LOG="$TMP_DIR/stage882-owner-local-accepted-commit-application-plan-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage882 owner-local accepted commit application plan suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE881_SUITE_PACKET" ]] || ! grep -F "stage881_owner_local_accepted_commit_inspection_suite_passed=true" "$STAGE881_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE881_TMPDIR="$TMP_DIR/stage881" zsh "$STAGE881_SUITE_SCRIPT" >/dev/null
  STAGE881_SUITE_PACKET="$TMP_DIR/stage881/stage881-owner-local-accepted-commit-inspection-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage881_owner_local_accepted_commit_inspection_suite_passed=true" \
  "stage882_owner_local_accepted_commit_application_plan_prepared=true" \
  "accepted_commit_inspection_bound_to_acceptance_runtime=true"; do
  require_file_fact "$STAGE881_SUITE_PACKET" "$fact"
done

for fact in \
  "stage881_owner_local_accepted_commit_inspection_consumed=true" \
  "owner_local_accepted_commit_application_plan_materialized=true" \
  "accepted_commit_patch_application_ledger_materialized=true" \
  "accepted_commit_rollback_token_materialized=true" \
  "accepted_commit_not_published_receipt_materialized=true" \
  "state_store_write_preview_boundary_materialized=true" \
  "accepted_commit_application_plan_bound_to_inspection_gate=true" \
  "stage883_owner_local_accepted_commit_demo_surface_prepared=true" \
  "state_store_write_executed=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage882_owner_local_accepted_commit_application_plan_suite_version=1"
  echo "stage881_suite_packet=$STAGE881_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage883_owner_local_accepted_commit_demo_surface_after_stage882"
  echo "stage882_owner_local_accepted_commit_application_plan_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage882 owner-local accepted commit application plan suite: route_classification=accepted_commit_application_plan"
echo "cjgui stage882 owner-local accepted commit application plan suite: suite_packet_path=$SUITE_PACKET"
