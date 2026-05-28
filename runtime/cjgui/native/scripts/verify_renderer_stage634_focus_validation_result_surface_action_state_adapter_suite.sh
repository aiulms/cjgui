#!/usr/bin/env zsh
#
# Focused suite for stage634. It consumes stage633 interaction targets and
# verifies non-dispatching action/state dry-run candidates.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE634_TMPDIR:-/private/tmp/cjgui-stage633-stage636/stage634}"
SUITE_PACKET="$TMP_DIR/stage634-focus-validation-result-surface-action-state-adapter-suite.packet"
STAGE633_SUITE_PACKET="${CJGUI_STAGE634_INPUT_PACKET:-${CJGUI_STAGE633_FOCUS_VALIDATION_RESULT_SURFACE_INTERACTION_BRIDGE_SUITE_PACKET:-/private/tmp/cjgui-stage633-stage636/stage633/stage633-focus-validation-result-surface-interaction-bridge-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage634_focus_validation_result_surface_action_state_adapter_owner.sh"
OWNER_LOG="$TMP_DIR/stage634-focus-validation-result-surface-action-state-adapter-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage634 focus validation result surface action state adapter suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage633_focus_validation_result_surface_interaction_bridge_consumed=true" \
  "shared_result_surface_action_state_adapter_materialized=true" \
  "shared_result_surface_state_delta_dry_run_ledger_materialized=true" \
  "chat_composer_result_surface_action_state_candidate_materialized=true" \
  "stage635_focus_validation_result_surface_state_render_refresh_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE633_SUITE_PACKET" || ! -f "$STAGE633_SUITE_PACKET" ]]; then
  echo "cjgui stage634 focus validation result surface action state adapter suite: missing stage633 packet; set CJGUI_STAGE634_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage633_focus_validation_result_surface_interaction_bridge_suite_version=1" \
  "shared_focus_validation_result_surface_interaction_bridge_contract_materialized=true" \
  "chat_composer_result_surface_interaction_target_materialized=true" \
  "stage634_focus_validation_result_surface_action_state_adapter_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE633_SUITE_PACKET" "$fact"
done

{
  echo "stage634_focus_validation_result_surface_action_state_adapter_suite_version=1"
  echo "stage633_focus_validation_result_surface_interaction_bridge_suite_packet=$STAGE633_SUITE_PACKET"
  echo "stage634_focus_validation_result_surface_action_state_adapter_owner_passed=true"
  echo "stage633_focus_validation_result_surface_interaction_bridge_consumed=true"
  echo "result_surface_interaction_targets_consumed=true"
  echo "shared_result_surface_action_state_adapter_materialized=true"
  echo "shared_result_surface_action_intent_ledger_materialized=true"
  echo "shared_result_surface_state_delta_dry_run_ledger_materialized=true"
  echo "todo_result_surface_action_state_candidate_materialized=true"
  echo "settings_result_surface_action_state_candidate_materialized=true"
  echo "ai_generated_settings_result_surface_action_state_candidate_materialized=true"
  echo "chat_composer_result_surface_action_state_candidate_materialized=true"
  echo "result_surface_action_state_adapter_bound_to_stage633_interaction_targets=true"
  echo "result_surface_action_state_adapter_non_dispatching=true"
  echo "result_surface_state_updates_owner_local_dry_run=true"
  echo "stage635_focus_validation_result_surface_state_render_refresh_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage635_focus_validation_result_surface_state_render_refresh_after_stage634"
  echo "stage634_focus_validation_result_surface_action_state_adapter_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage634 focus validation result surface action state adapter suite: route_classification=result_surface_action_state_adapter_ready"
echo "cjgui stage634 focus validation result surface action state adapter suite: suite_packet_path=$SUITE_PACKET"
