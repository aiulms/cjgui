#!/usr/bin/env zsh
#
# Focused suite for stage753. It consumes stage752 and verifies that
# acceptance commit preflight remains owner-local and dry-run-only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE753_TMPDIR:-/private/tmp/cjgui-stage753-stage756/stage753}"
SUITE_PACKET="$TMP_DIR/stage753-ai-generated-ui-acceptance-commit-preflight-suite.packet"
STAGE752_SUITE_PACKET="${CJGUI_STAGE753_INPUT_PACKET:-${CJGUI_STAGE752_AI_GENERATED_UI_OWNER_ACCEPTANCE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage749-stage752/stage752/stage752-ai-generated-ui-owner-acceptance-runtime-manager-suite.packet}}"
STAGE752_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage753_ai_generated_ui_acceptance_commit_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage753-ai-generated-ui-acceptance-commit-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage753 ai generated ui acceptance commit preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE752_SUITE_PACKET" ]] || ! grep -F "stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite_passed=true" "$STAGE752_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE752_TMPDIR="$TMP_DIR/stage752" zsh "$STAGE752_SUITE_SCRIPT" >/dev/null
  STAGE752_SUITE_PACKET="$TMP_DIR/stage752/stage752-ai-generated-ui-owner-acceptance-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage752_ai_generated_ui_owner_acceptance_runtime_manager_consumed=true" \
  "owner_local_acceptance_commit_candidate_ledger_materialized=true" \
  "acceptance_commit_capability_ledger_materialized=true" \
  "acceptance_commit_validation_gate_materialized=true" \
  "resolver_result_to_acceptance_commit_plan_bridge_materialized=true" \
  "acceptance_commit_preflight_bound_to_owner_acceptance_runtime_manager=true" \
  "stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_prepared=true" \
  "owner_acceptance_granted=false" \
  "acceptance_commit_committed=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite_passed=true" \
  "shared_ai_generated_ui_owner_acceptance_runtime_manager_materialized=true" \
  "owner_acceptance_runtime_contract_materialized=true" \
  "owner_acceptance_execution_receipt_contract_materialized=true" \
  "stage753_ai_generated_ui_acceptance_commit_preflight_prepared=true" \
  "owner_acceptance_granted=false"; do
  require_file_fact "$STAGE752_SUITE_PACKET" "$fact"
done

{
  echo "stage753_ai_generated_ui_acceptance_commit_preflight_suite_version=1"
  echo "stage752_ai_generated_ui_owner_acceptance_runtime_manager_suite_packet=$STAGE752_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage753_ai_generated_ui_acceptance_commit_preflight_suite_passed=true"
  echo "next_route=stage754_ai_generated_ui_acceptance_commit_rollback_snapshot_after_stage753"
} > "$SUITE_PACKET"

echo "cjgui stage753 ai generated ui acceptance commit preflight suite: route_classification=acceptance_commit_preflight_ready"
echo "cjgui stage753 ai generated ui acceptance commit preflight suite: suite_packet_path=$SUITE_PACKET"
