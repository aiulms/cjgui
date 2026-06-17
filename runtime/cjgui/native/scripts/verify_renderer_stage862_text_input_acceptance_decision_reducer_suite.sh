#!/usr/bin/env zsh
#
# Focused suite for stage862. It consumes stage861 and records the
# non-dispatching owner acceptance decision reducer.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE862_TMPDIR:-/private/tmp/cjgui-stage861-stage864/stage862}"
SUITE_PACKET="$TMP_DIR/stage862-text-input-acceptance-decision-reducer-suite.packet"
STAGE861_SUITE_PACKET="${CJGUI_STAGE862_INPUT_PACKET:-${CJGUI_STAGE861_TEXT_INPUT_OWNER_ACCEPTANCE_REVIEW_GATE_SUITE_PACKET:-/private/tmp/cjgui-stage861-stage864/stage861/stage861-text-input-owner-acceptance-review-gate-suite.packet}}"
STAGE861_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage861_text_input_owner_acceptance_review_gate_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage862_text_input_acceptance_decision_reducer_owner.sh"
OWNER_LOG="$TMP_DIR/stage862-text-input-acceptance-decision-reducer-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage862 text input acceptance decision reducer suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE861_SUITE_PACKET" ]] || ! grep -F "stage861_text_input_owner_acceptance_review_gate_suite_passed=true" "$STAGE861_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE861_TMPDIR="$TMP_DIR/stage861" zsh "$STAGE861_SUITE_SCRIPT" >/dev/null
  STAGE861_SUITE_PACKET="$TMP_DIR/stage861/stage861-text-input-owner-acceptance-review-gate-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage861_text_input_owner_acceptance_review_gate_consumed=true" \
  "stage860_owner_local_text_input_commit_runtime_manager_consumed_transitively=true" \
  "owner_acceptance_accepted_decision_candidate_materialized=true" \
  "owner_acceptance_rejected_decision_candidate_materialized=true" \
  "owner_acceptance_request_changes_decision_candidate_materialized=true" \
  "owner_acceptance_rollback_snapshot_selection_materialized=true" \
  "owner_acceptance_not_published_receipt_materialized=true" \
  "owner_acceptance_decision_reducer_bound_to_stage861_review_gate=true" \
  "stage863_text_input_acceptance_demo_host_surface_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

require_file_fact "$STAGE861_SUITE_PACKET" "stage861_text_input_owner_acceptance_review_gate_suite_passed=true"
require_file_fact "$STAGE861_SUITE_PACKET" "owner_acceptance_review_gate_materialized=true"

{
  echo "stage862_text_input_acceptance_decision_reducer_suite_version=1"
  echo "stage861_suite_packet=$STAGE861_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage863_text_input_acceptance_demo_host_surface_after_stage862"
  echo "stage862_text_input_acceptance_decision_reducer_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage862 text input acceptance decision reducer suite: route_classification=acceptance_decision_reducer"
echo "cjgui stage862 text input acceptance decision reducer suite: suite_packet_path=$SUITE_PACKET"
