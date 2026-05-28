#!/usr/bin/env zsh
#
# Focused suite for stage623. It consumes stage622 host frames and verifies
# checkable host interaction receipts and probe input.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE623_TMPDIR:-/private/tmp/cjgui-stage621-stage624/stage623}"
SUITE_PACKET="$TMP_DIR/stage623-focus-validation-host-interaction-receipt-suite.packet"
STAGE622_SUITE_PACKET="${CJGUI_STAGE623_INPUT_PACKET:-${CJGUI_STAGE622_FOCUS_VALIDATION_HOST_FRAME_ASSEMBLY_SUITE_PACKET:-/private/tmp/cjgui-stage621-stage624/stage622/stage622-focus-validation-host-frame-assembly-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage623_focus_validation_host_interaction_receipt_owner.sh"
OWNER_LOG="$TMP_DIR/stage623-focus-validation-host-interaction-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage623 focus validation host interaction receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE622_SUITE_PACKET" || ! -f "$STAGE622_SUITE_PACKET" ]]; then
  echo "cjgui stage623 focus validation host interaction receipt suite: missing stage622 packet; set CJGUI_STAGE623_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage622_focus_validation_host_frame_assembly_suite_version=1" \
  "shared_focus_validation_host_frame_assembly_materialized=true" \
  "host_frame_assembly_bound_to_stage621_host_integration=true" \
  "stage623_focus_validation_host_interaction_receipt_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE622_SUITE_PACKET" "$fact"
done

for fact in \
  "stage622_focus_validation_host_frame_assembly_consumed=true" \
  "shared_focus_validation_host_interaction_receipt_materialized=true" \
  "demo_host_inspection_probe_input_materialized=true" \
  "host_interaction_receipt_bound_to_stage620_runtime_contract=true" \
  "stage624_shared_focus_validation_demo_host_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage623_focus_validation_host_interaction_receipt_suite_version=1"
  echo "stage622_focus_validation_host_frame_assembly_suite_packet=$STAGE622_SUITE_PACKET"
  echo "stage623_focus_validation_host_interaction_receipt_owner_passed=true"
  echo "stage622_focus_validation_host_frame_assembly_consumed=true"
  echo "stage621_focus_validation_host_integration_consumed_transitively=true"
  echo "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed_transitively=true"
  echo "focus_validation_host_frames_consumed=true"
  echo "shared_focus_validation_host_interaction_receipt_materialized=true"
  echo "focus_transition_preview_receipt_materialized=true"
  echo "validation_display_refresh_receipt_materialized=true"
  echo "input_feedback_display_receipt_materialized=true"
  echo "demo_host_inspection_probe_input_materialized=true"
  echo "todo_focus_validation_host_interaction_receipt_materialized=true"
  echo "settings_focus_validation_host_interaction_receipt_materialized=true"
  echo "ai_generated_settings_focus_validation_host_interaction_receipt_materialized=true"
  echo "chat_composer_focus_validation_host_interaction_receipt_materialized=true"
  echo "host_interaction_receipt_bound_to_stage622_frame_assembly=true"
  echo "host_interaction_receipt_bound_to_stage620_runtime_contract=true"
  echo "stage624_shared_focus_validation_demo_host_runtime_contract_prepared=true"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage623_focus_validation_host_interaction_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage623 focus validation host interaction receipt suite: route_classification=focus_validation_host_interaction_receipt_ready"
echo "cjgui stage623 focus validation host interaction receipt suite: suite_packet_path=$SUITE_PACKET"
