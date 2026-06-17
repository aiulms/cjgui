#!/usr/bin/env zsh
#
# Focused suite for stage861. It consumes stage860 and records the owner
# acceptance review gate boundary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE861_TMPDIR:-/private/tmp/cjgui-stage861-stage864/stage861}"
SUITE_PACKET="$TMP_DIR/stage861-text-input-owner-acceptance-review-gate-suite.packet"
STAGE860_SUITE_PACKET="${CJGUI_STAGE861_INPUT_PACKET:-${CJGUI_STAGE860_OWNER_LOCAL_TEXT_INPUT_COMMIT_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage857-stage860/stage860/stage860-owner-local-text-input-commit-runtime-manager-suite.packet}}"
STAGE860_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage860_owner_local_text_input_commit_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage861_text_input_owner_acceptance_review_gate_owner.sh"
OWNER_LOG="$TMP_DIR/stage861-text-input-owner-acceptance-review-gate-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage861 text input owner acceptance review gate suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE860_SUITE_PACKET" ]] || ! grep -F "stage860_owner_local_text_input_commit_runtime_manager_suite_passed=true" "$STAGE860_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE860_TMPDIR="$TMP_DIR/stage860" zsh "$STAGE860_SUITE_SCRIPT" >/dev/null
  STAGE860_SUITE_PACKET="$TMP_DIR/stage860/stage860-owner-local-text-input-commit-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh -n "$0"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage860_owner_local_text_input_commit_runtime_manager_consumed=true" \
  "owner_local_text_input_commit_first_slice_consumed=true" \
  "owner_acceptance_review_gate_materialized=true" \
  "owner_acceptance_accept_decision_lane_materialized=true" \
  "owner_acceptance_reject_reason_lane_materialized=true" \
  "owner_acceptance_request_changes_lane_materialized=true" \
  "owner_acceptance_rollback_snapshot_review_lane_materialized=true" \
  "owner_acceptance_review_gate_bound_to_stage860_runtime_manager=true" \
  "stage862_text_input_acceptance_decision_reducer_prepared=true" \
  "owner_acceptance_granted=false" \
  "state_store_commit_published=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage860_owner_local_text_input_commit_runtime_manager_suite_passed=true" \
  "owner_local_text_input_commit_first_slice_materialized=true" \
  "owner_local_text_input_commit_applied=true" \
  "stage861_text_input_owner_acceptance_review_after_owner_local_commit_prepared=true"; do
  require_file_fact "$STAGE860_SUITE_PACKET" "$fact"
done

{
  echo "stage861_text_input_owner_acceptance_review_gate_suite_version=1"
  echo "stage860_suite_packet=$STAGE860_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "next_route=stage862_text_input_acceptance_decision_reducer_after_stage861"
  echo "stage861_text_input_owner_acceptance_review_gate_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage861 text input owner acceptance review gate suite: route_classification=owner_acceptance_review_gate"
echo "cjgui stage861 text input owner acceptance review gate suite: suite_packet_path=$SUITE_PACKET"
