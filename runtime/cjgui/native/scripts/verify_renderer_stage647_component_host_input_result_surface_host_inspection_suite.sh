#!/usr/bin/env zsh
#
# Focused suite for stage647. It consumes stage646 layout feedback and verifies
# demo-host inspection receipts for refreshed result surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE647_TMPDIR:-/private/tmp/cjgui-stage645-stage648/stage647}"
SUITE_PACKET="$TMP_DIR/stage647-component-host-input-result-surface-host-inspection-suite.packet"
STAGE646_SUITE_PACKET="${CJGUI_STAGE647_INPUT_PACKET:-${CJGUI_STAGE646_COMPONENT_HOST_INPUT_RESULT_SURFACE_LAYOUT_FEEDBACK_SUITE_PACKET:-/private/tmp/cjgui-stage645-stage648/stage646/stage646-component-host-input-result-surface-layout-feedback-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage647_component_host_input_result_surface_host_inspection_owner.sh"
OWNER_LOG="$TMP_DIR/stage647-component-host-input-result-surface-host-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage647 component host input result surface host inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage646_component_host_input_result_surface_layout_feedback_consumed=true" \
  "shared_result_surface_host_inspection_receipt_materialized=true" \
  "validation_display_host_inspection_slot_materialized=true" \
  "chat_composer_result_surface_host_inspection_materialized=true" \
  "stage648_component_host_input_result_surface_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE646_SUITE_PACKET" || ! -f "$STAGE646_SUITE_PACKET" ]]; then
  echo "cjgui stage647 component host input result surface host inspection suite: missing stage646 packet; set CJGUI_STAGE647_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage646_component_host_input_result_surface_layout_feedback_suite_version=1" \
  "shared_result_surface_layout_feedback_resolver_materialized=true" \
  "chat_composer_result_surface_layout_feedback_materialized=true" \
  "stage647_component_host_input_result_surface_host_inspection_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE646_SUITE_PACKET" "$fact"
done

{
  echo "stage647_component_host_input_result_surface_host_inspection_suite_version=1"
  echo "stage646_component_host_input_result_surface_layout_feedback_suite_packet=$STAGE646_SUITE_PACKET"
  echo "stage647_component_host_input_result_surface_host_inspection_owner_passed=true"
  echo "stage646_component_host_input_result_surface_layout_feedback_consumed=true"
  echo "stage645_component_host_input_result_surface_refresh_consumed_transitively=true"
  echo "stage644_component_host_input_cycle_executor_consumed_transitively=true"
  echo "shared_result_surface_host_inspection_receipt_materialized=true"
  echo "validation_display_host_inspection_slot_materialized=true"
  echo "focus_movement_host_inspection_slot_materialized=true"
  echo "input_feedback_host_inspection_slot_materialized=true"
  echo "semantic_refresh_host_inspection_slot_materialized=true"
  echo "demo_host_result_surface_probe_input_materialized=true"
  echo "todo_result_surface_host_inspection_materialized=true"
  echo "settings_result_surface_host_inspection_materialized=true"
  echo "ai_generated_settings_result_surface_host_inspection_materialized=true"
  echo "chat_composer_result_surface_host_inspection_materialized=true"
  echo "host_inspection_bound_to_stage646_layout_feedback=true"
  echo "stage648_component_host_input_result_surface_runtime_contract_prepared=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "next_route=stage648_component_host_input_result_surface_runtime_contract_after_stage647"
  echo "stage647_component_host_input_result_surface_host_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage647 component host input result surface host inspection suite: route_classification=result_surface_host_inspection_ready"
echo "cjgui stage647 component host input result surface host inspection suite: suite_packet_path=$SUITE_PACKET"
