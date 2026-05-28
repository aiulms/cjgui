#!/usr/bin/env zsh
#
# Focused suite for stage622. It consumes stage621 host integration slots and
# verifies non-publishing host frame assembly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE622_TMPDIR:-/private/tmp/cjgui-stage621-stage624/stage622}"
SUITE_PACKET="$TMP_DIR/stage622-focus-validation-host-frame-assembly-suite.packet"
STAGE621_SUITE_PACKET="${CJGUI_STAGE622_INPUT_PACKET:-${CJGUI_STAGE621_FOCUS_VALIDATION_HOST_INTEGRATION_SUITE_PACKET:-/private/tmp/cjgui-stage621-stage624/stage621/stage621-focus-validation-host-integration-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage622_focus_validation_host_frame_assembly_owner.sh"
OWNER_LOG="$TMP_DIR/stage622-focus-validation-host-frame-assembly-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage622 focus validation host frame assembly suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

if [[ -z "$STAGE621_SUITE_PACKET" || ! -f "$STAGE621_SUITE_PACKET" ]]; then
  echo "cjgui stage622 focus validation host frame assembly suite: missing stage621 packet; set CJGUI_STAGE622_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage621_focus_validation_host_integration_suite_version=1" \
  "shared_focus_validation_host_integration_slot_materialized=true" \
  "host_integration_bound_to_stage620_runtime_contract=true" \
  "stage622_focus_validation_host_frame_assembly_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE621_SUITE_PACKET" "$fact"
done

for fact in \
  "stage621_focus_validation_host_integration_consumed=true" \
  "shared_focus_validation_host_frame_assembly_materialized=true" \
  "focus_handoff_frame_slot_materialized=true" \
  "host_frame_assembly_non_publishing=true" \
  "stage623_focus_validation_host_interaction_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

{
  echo "stage622_focus_validation_host_frame_assembly_suite_version=1"
  echo "stage621_focus_validation_host_integration_suite_packet=$STAGE621_SUITE_PACKET"
  echo "stage622_focus_validation_host_frame_assembly_owner_passed=true"
  echo "stage621_focus_validation_host_integration_consumed=true"
  echo "stage620_shared_focus_validation_input_cycle_runtime_contract_consumed_transitively=true"
  echo "host_integration_slots_consumed=true"
  echo "shared_focus_validation_host_frame_assembly_materialized=true"
  echo "validation_display_frame_slot_materialized=true"
  echo "focus_handoff_frame_slot_materialized=true"
  echo "input_feedback_frame_slot_materialized=true"
  echo "semantic_diff_frame_slot_materialized=true"
  echo "todo_focus_validation_host_frame_materialized=true"
  echo "settings_focus_validation_host_frame_materialized=true"
  echo "ai_generated_settings_focus_validation_host_frame_materialized=true"
  echo "chat_composer_focus_validation_host_frame_materialized=true"
  echo "host_frame_assembly_bound_to_stage621_host_integration=true"
  echo "host_frame_assembly_owner_local=true"
  echo "host_frame_assembly_non_publishing=true"
  echo "stage623_focus_validation_host_interaction_receipt_prepared=true"
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
  echo "stage622_focus_validation_host_frame_assembly_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage622 focus validation host frame assembly suite: route_classification=focus_validation_host_frame_assembly_ready"
echo "cjgui stage622 focus validation host frame assembly suite: suite_packet_path=$SUITE_PACKET"
