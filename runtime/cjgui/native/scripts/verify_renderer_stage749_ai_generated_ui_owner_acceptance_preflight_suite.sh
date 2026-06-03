#!/usr/bin/env zsh
#
# Focused suite for stage749. It consumes stage748 and verifies the
# AI-generated UI owner acceptance preflight stays internal-only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE749_TMPDIR:-/private/tmp/cjgui-stage749-stage752/stage749}"
SUITE_PACKET="$TMP_DIR/stage749-ai-generated-ui-owner-acceptance-preflight-suite.packet"
STAGE748_SUITE_PACKET="${CJGUI_STAGE749_INPUT_PACKET:-${CJGUI_STAGE748_AI_GENERATED_UI_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage745-stage748/stage748/stage748-ai-generated-ui-runtime-manager-suite.packet}}"
STAGE748_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage748_ai_generated_ui_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage749_ai_generated_ui_owner_acceptance_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage749-ai-generated-ui-owner-acceptance-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage749 ai generated ui owner acceptance preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE748_SUITE_PACKET" ]] || ! grep -F "stage748_ai_generated_ui_runtime_manager_suite_passed=true" "$STAGE748_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE748_TMPDIR="$TMP_DIR/stage748" zsh "$STAGE748_SUITE_SCRIPT" >/dev/null
  STAGE748_SUITE_PACKET="$TMP_DIR/stage748/stage748-ai-generated-ui-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage748_ai_generated_ui_runtime_manager_consumed=true" \
  "owner_acceptance_preflight_rows_materialized=true" \
  "owner_acceptance_candidate_ledger_materialized=true" \
  "owner_risk_classification_ledger_materialized=true" \
  "owner_reject_reason_ledger_materialized=true" \
  "owner_acceptance_preflight_bound_to_ai_generated_ui_runtime_manager=true" \
  "stage750_ai_generated_ui_public_surface_preflight_prepared=true" \
  "owner_acceptance_granted=false" \
  "public_component_api_added=false" \
  "stable_public_api_added=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage748_ai_generated_ui_runtime_manager_suite_passed=true" \
  "shared_ai_generated_ui_authoring_runtime_manager_materialized=true" \
  "ai_generated_ui_authoring_runtime_contract_materialized=true" \
  "ai_generated_ui_execution_receipt_contract_materialized=true" \
  "stage749_ai_generated_ui_owner_acceptance_preflight_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE748_SUITE_PACKET" "$fact"
done

{
  echo "stage749_ai_generated_ui_owner_acceptance_preflight_suite_version=1"
  echo "stage748_ai_generated_ui_runtime_manager_suite_packet=$STAGE748_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage749_ai_generated_ui_owner_acceptance_preflight_suite_passed=true"
  echo "next_route=stage750_ai_generated_ui_public_surface_preflight_after_stage749"
} > "$SUITE_PACKET"

echo "cjgui stage749 ai generated ui owner acceptance preflight suite: route_classification=owner_acceptance_preflight_ready"
echo "cjgui stage749 ai generated ui owner acceptance preflight suite: suite_packet_path=$SUITE_PACKET"
