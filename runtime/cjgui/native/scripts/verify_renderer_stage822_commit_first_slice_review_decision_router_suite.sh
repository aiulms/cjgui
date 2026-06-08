#!/usr/bin/env zsh
#
# Focused suite for stage822. It consumes stage821 and records accept/reject /
# request-changes decision routing without committing state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE822_TMPDIR:-/private/tmp/cjgui-stage821-stage824/stage822}"
SUITE_PACKET="$TMP_DIR/stage822-commit-first-slice-review-decision-router-suite.packet"
STAGE821_SUITE_PACKET="${CJGUI_STAGE822_INPUT_PACKET:-${CJGUI_STAGE821_COMMIT_FIRST_SLICE_OWNER_REVIEW_GATE_SUITE_PACKET:-/private/tmp/cjgui-stage821-stage824/stage821/stage821-commit-first-slice-owner-review-gate-suite.packet}}"
STAGE821_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage821_commit_first_slice_owner_review_gate_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage822_commit_first_slice_review_decision_router_owner.sh"
OWNER_LOG="$TMP_DIR/stage822-commit-first-slice-review-decision-router-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage822 commit first-slice review decision router suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE821_SUITE_PACKET" ]] || ! grep -F "stage821_commit_first_slice_owner_review_gate_suite_passed=true" "$STAGE821_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE821_TMPDIR="$TMP_DIR/stage821" zsh "$STAGE821_SUITE_SCRIPT" >/dev/null
  STAGE821_SUITE_PACKET="$TMP_DIR/stage821/stage821-commit-first-slice-owner-review-gate-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage821_commit_first_slice_owner_review_gate_consumed=true" \
  "commit_first_slice_accept_review_decision_route_materialized=true" \
  "commit_first_slice_reject_review_decision_route_materialized=true" \
  "commit_first_slice_request_changes_review_decision_route_materialized=true" \
  "commit_first_slice_rollback_hold_decision_route_materialized=true" \
  "commit_first_slice_commit_candidate_hold_ledger_materialized=true" \
  "commit_first_slice_review_decision_router_bound_to_stage821_gate=true" \
  "stage823_commit_first_slice_owner_review_demo_host_surface_prepared=true" \
  "state_store_commit_published=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage821_commit_first_slice_owner_review_gate_suite_passed=true" \
  "commit_first_slice_owner_review_gate_materialized=true" \
  "commit_first_slice_acceptability_review_route_materialized=true"; do
  require_file_fact "$STAGE821_SUITE_PACKET" "$fact"
done

{
  echo "stage822_commit_first_slice_review_decision_router_suite_version=1"
  echo "stage821_suite_packet=$STAGE821_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage822_commit_first_slice_review_decision_router_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage822 commit first-slice review decision router suite: route_classification=commit_review_decision_router"
echo "cjgui stage822 commit first-slice review decision router suite: suite_packet_path=$SUITE_PACKET"
