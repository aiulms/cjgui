#!/usr/bin/env zsh
#
# Focused suite for stage853. It consumes stage852 and records text-input commit preflight.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE853_TMPDIR:-/private/tmp/cjgui-stage853-stage856/stage853}"
SUITE_PACKET="$TMP_DIR/stage853-text-input-commit-preflight-suite.packet"
STAGE852_SUITE_PACKET="${CJGUI_STAGE853_INPUT_PACKET:-${CJGUI_STAGE852_PUBLISHABLE_STATE_TEXT_INPUT_STATE_UPDATE_RENDER_BRIDGE_RUNTIME_MANAGER_SUITE_PACKET:-/private/tmp/cjgui-stage849-stage852/stage852/stage852-publishable-state-text-input-state-update-render-bridge-runtime-manager-suite.packet}}"
STAGE852_SUITE_SCRIPT="$SCRIPT_DIR/verify_renderer_stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_suite.sh"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage853_text_input_commit_preflight_owner.sh"
OWNER_LOG="$TMP_DIR/stage853-text-input-commit-preflight-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage853 text input commit preflight suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -f "$STAGE852_SUITE_PACKET" ]] || ! grep -F "stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_suite_passed=true" "$STAGE852_SUITE_PACKET" >/dev/null 2>&1; then
  CJGUI_STAGE852_TMPDIR="$TMP_DIR/stage852" zsh "$STAGE852_SUITE_SCRIPT" >/dev/null
  STAGE852_SUITE_PACKET="$TMP_DIR/stage852/stage852-publishable-state-text-input-state-update-render-bridge-runtime-manager-suite.packet"
fi

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage852_text_input_state_update_render_bridge_runtime_manager_consumed=true" \
  "text_input_state_update_render_bridge_runtime_contract_consumed=true" \
  "shared_text_input_commit_preflight_materialized=true" \
  "text_input_commit_candidate_ledger_materialized=true" \
  "text_input_commit_compatibility_gate_materialized=true" \
  "text_input_result_to_commit_plan_bridge_materialized=true" \
  "file_browser_text_input_commit_preflight_surface_materialized=true" \
  "text_input_commit_preflight_dry_run_only=true" \
  "stage854_text_input_commit_rollback_snapshot_prepared=true" \
  "text_input_commit_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

for fact in \
  "stage852_publishable_state_text_input_state_update_render_bridge_runtime_manager_suite_passed=true" \
  "file_browser_text_input_state_update_runtime_surface_materialized=true" \
  "stage853_publishable_state_text_input_commit_preflight_prepared=true" \
  "state_update_committed=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE852_SUITE_PACKET" "$fact"
done

{
  echo "stage853_text_input_commit_preflight_suite_version=1"
  echo "stage852_suite_packet=$STAGE852_SUITE_PACKET"
  cat "$OWNER_LOG"
  echo "stage853_text_input_commit_preflight_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage853 text input commit preflight suite: route_classification=text_input_commit_preflight"
echo "cjgui stage853 text input commit preflight suite: suite_packet_path=$SUITE_PACKET"
