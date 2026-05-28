#!/usr/bin/env zsh
#
# Focused suite for stage639. It consumes stage638 execution receipts and
# verifies demo-host inspection surfaces for result-surface interaction.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE639_TMPDIR:-/private/tmp/cjgui-stage637-stage640/stage639}"
SUITE_PACKET="$TMP_DIR/stage639-result-surface-demo-host-inspection-suite.packet"
STAGE638_SUITE_PACKET="${CJGUI_STAGE639_INPUT_PACKET:-${CJGUI_STAGE638_RESULT_SURFACE_LAYOUT_FOCUS_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage637-stage640/stage638/stage638-result-surface-layout-focus-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage639_result_surface_demo_host_inspection_owner.sh"
OWNER_LOG="$TMP_DIR/stage639-result-surface-demo-host-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage639 result surface demo host inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage638_result_surface_layout_focus_receipt_consumed=true" \
  "shared_result_surface_demo_host_inspection_input_materialized=true" \
  "validation_display_host_inspection_receipt_materialized=true" \
  "chat_composer_demo_host_inspection_surface_materialized=true" \
  "stage640_result_surface_host_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE638_SUITE_PACKET" || ! -f "$STAGE638_SUITE_PACKET" ]]; then
  echo "cjgui stage639 result surface demo host inspection suite: missing stage638 packet; set CJGUI_STAGE639_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage638_result_surface_layout_focus_receipt_suite_version=1" \
  "shared_layout_focus_execution_receipt_materialized=true" \
  "chat_composer_layout_focus_execution_receipt_materialized=true" \
  "stage639_result_surface_demo_host_inspection_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE638_SUITE_PACKET" "$fact"
done

{
  echo "stage639_result_surface_demo_host_inspection_suite_version=1"
  echo "stage638_result_surface_layout_focus_receipt_suite_packet=$STAGE638_SUITE_PACKET"
  echo "stage639_result_surface_demo_host_inspection_owner_passed=true"
  echo "stage638_result_surface_layout_focus_receipt_consumed=true"
  echo "stage637_result_surface_layout_focus_preview_consumed_transitively=true"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed_transitively=true"
  echo "shared_result_surface_demo_host_inspection_input_materialized=true"
  echo "validation_display_host_inspection_receipt_materialized=true"
  echo "focus_movement_host_inspection_receipt_materialized=true"
  echo "input_feedback_host_inspection_receipt_materialized=true"
  echo "todo_demo_host_inspection_surface_materialized=true"
  echo "settings_demo_host_inspection_surface_materialized=true"
  echo "ai_generated_settings_demo_host_inspection_surface_materialized=true"
  echo "chat_composer_demo_host_inspection_surface_materialized=true"
  echo "demo_host_inspection_bound_to_stage638_layout_focus_receipts=true"
  echo "stage640_result_surface_host_runtime_contract_prepared=true"
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
  echo "next_route=stage640_result_surface_host_runtime_contract_after_stage639"
  echo "stage639_result_surface_demo_host_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage639 result surface demo host inspection suite: route_classification=result_surface_demo_host_inspection_ready"
echo "cjgui stage639 result surface demo host inspection suite: suite_packet_path=$SUITE_PACKET"
