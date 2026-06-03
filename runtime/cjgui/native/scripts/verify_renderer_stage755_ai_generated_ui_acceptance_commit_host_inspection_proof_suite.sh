#!/usr/bin/env zsh
#
# Focused suite for stage755. It consumes stage754 and verifies a checkable
# host inspection proof without mutating host UI or renderer state.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE755_TMPDIR:-/private/tmp/cjgui-stage753-stage756/stage755}"
SUITE_PACKET="$TMP_DIR/stage755-ai-generated-ui-acceptance-commit-host-inspection-proof-suite.packet"
STAGE754_SUITE_PACKET="${CJGUI_STAGE755_INPUT_PACKET:-${CJGUI_STAGE754_AI_GENERATED_UI_ACCEPTANCE_COMMIT_ROLLBACK_SNAPSHOT_SUITE_PACKET:-/private/tmp/cjgui-stage753-stage756/stage754/stage754-ai-generated-ui-acceptance-commit-rollback-snapshot-suite.packet}}"
STAGE754_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_owner.sh"
OWNER_LOG="$TMP_DIR/stage755-ai-generated-ui-acceptance-commit-host-inspection-proof-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage755 ai generated ui acceptance commit host inspection proof suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE754_SUITE_PACKET" ]] || ! grep -F "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite_passed=true" "$STAGE754_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE754_TMPDIR="$TMP_DIR/stage754" zsh "$STAGE754_SUITE_SCRIPT" >/dev/null
  STAGE754_SUITE_PACKET="$TMP_DIR/stage754/stage754-ai-generated-ui-acceptance-commit-rollback-snapshot-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_consumed=true" \
  "acceptance_commit_rollback_base_snapshot_consumed=true" \
  "acceptance_pending_commit_snapshot_consumed=true" \
  "acceptance_commit_host_inspection_rows_materialized=true" \
  "acceptance_commit_slot_diff_rows_materialized=true" \
  "acceptance_commit_result_surface_preview_materialized=true" \
  "acceptance_commit_render_command_refresh_receipt_materialized=true" \
  "acceptance_commit_semantic_diff_explain_materialized=true" \
  "acceptance_commit_probe_input_contract_materialized=true" \
  "host_inspection_proof_bound_to_rollback_snapshot=true" \
  "stage756_ai_generated_ui_acceptance_commit_runtime_manager_prepared=true" \
  "acceptance_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite_passed=true" \
  "acceptance_commit_rollback_base_snapshot_materialized=true" \
  "acceptance_pending_commit_snapshot_materialized=true" \
  "acceptance_rollback_token_ledger_materialized=true" \
  "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_prepared=true"; do
  require_file_fact "$STAGE754_SUITE_PACKET" "$fact"
done

{
  echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite_version=1"
  echo "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_suite_packet=$STAGE754_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage755_ai_generated_ui_acceptance_commit_host_inspection_proof_suite_passed=true"
  echo "next_route=stage756_ai_generated_ui_acceptance_commit_runtime_manager_after_stage755"
} > "$SUITE_PACKET"

echo "cjgui stage755 ai generated ui acceptance commit host inspection proof suite: route_classification=acceptance_commit_host_inspection_proof_ready"
echo "cjgui stage755 ai generated ui acceptance commit host inspection proof suite: suite_packet_path=$SUITE_PACKET"
