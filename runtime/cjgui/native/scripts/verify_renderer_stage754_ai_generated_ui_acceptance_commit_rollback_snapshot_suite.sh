#!/usr/bin/env zsh
#
# Focused suite for stage754. It consumes stage753 and verifies rollback
# snapshots are materialized without committing owner-local state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE754_TMPDIR:-/private/tmp/cjgui-stage753-stage756/stage754}"
SUITE_PACKET="$TMP_DIR/stage754-ai-generated-ui-acceptance-commit-rollback-snapshot-suite.packet"
STAGE753_SUITE_PACKET="${CJGUI_STAGE754_INPUT_PACKET:-${CJGUI_STAGE753_AI_GENERATED_UI_ACCEPTANCE_COMMIT_PREFLIGHT_SUITE_PACKET:-/private/tmp/cjgui-stage753-stage756/stage753/stage753-ai-generated-ui-acceptance-commit-preflight-suite.packet}}"
STAGE753_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage753_ai_generated_ui_acceptance_commit_preflight_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_owner.sh"
OWNER_LOG="$TMP_DIR/stage754-ai-generated-ui-acceptance-commit-rollback-snapshot-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage754 ai generated ui acceptance commit rollback snapshot suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE753_SUITE_PACKET" ]] || ! grep -F "stage753_ai_generated_ui_acceptance_commit_preflight_suite_passed=true" "$STAGE753_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE753_TMPDIR="$TMP_DIR/stage753" zsh "$STAGE753_SUITE_SCRIPT" >/dev/null
  STAGE753_SUITE_PACKET="$TMP_DIR/stage753/stage753-ai-generated-ui-acceptance-commit-preflight-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage753_ai_generated_ui_acceptance_commit_preflight_consumed=true" \
  "owner_local_acceptance_commit_candidate_ledger_consumed=true" \
  "acceptance_commit_rollback_base_snapshot_materialized=true" \
  "acceptance_pending_commit_snapshot_materialized=true" \
  "owner_reject_rollback_branch_materialized=true" \
  "validation_failure_rollback_branch_materialized=true" \
  "acceptance_conflict_classifier_materialized=true" \
  "acceptance_rollback_token_ledger_materialized=true" \
  "rollback_snapshot_bound_to_acceptance_commit_preflight=true" \
  "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_prepared=true" \
  "acceptance_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage753_ai_generated_ui_acceptance_commit_preflight_suite_passed=true" \
  "owner_local_acceptance_commit_candidate_ledger_materialized=true" \
  "acceptance_commit_validation_gate_materialized=true" \
  "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_prepared=true"; do
  require_file_fact "$STAGE753_SUITE_PACKET" "$fact"
done

{
  echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite_version=1"
  echo "stage753_ai_generated_ui_acceptance_commit_preflight_suite_packet=$STAGE753_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite_passed=true"
  echo "next_route=stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_after_stage754"
} > "$SUITE_PACKET"

echo "cjgui stage754 ai generated ui acceptance commit rollback snapshot suite: route_classification=acceptance_commit_rollback_snapshot_ready"
echo "cjgui stage754 ai generated ui acceptance commit rollback snapshot suite: suite_packet_path=$SUITE_PACKET"
