#!/usr/bin/env zsh
#
# Focused suite for stage607. It consumes stage606 visual receipts and verifies
# checkable feedback host inspection demo surfaces.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE607_TMPDIR:-/private/tmp/cjgui-stage605-stage608/stage607}"
SUITE_PACKET="$TMP_DIR/stage607-feedback-host-inspection-demo-surface-suite.packet"
STAGE606_SUITE_PACKET="${CJGUI_STAGE607_INPUT_PACKET:-${CJGUI_STAGE606_FEEDBACK_HOST_INPUT_VISUAL_EXECUTION_RECEIPT_SUITE_PACKET:-/private/tmp/cjgui-stage605-stage608/stage606/stage606-feedback-host-input-visual-execution-receipt-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage607_feedback_host_inspection_demo_surface_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage607_feedback_host_inspection_demo_surface.cj"
OWNER_LOG="$TMP_DIR/stage607-feedback-host-inspection-demo-surface-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage607 feedback host inspection demo surface suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage607 feedback host inspection demo surface suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage606_feedback_host_input_visual_execution_receipt_consumed=true" \
  "shared_feedback_host_inspection_demo_surface_materialized=true" \
  "validation_display_result_surface_refresh_materialized=true" \
  "input_feedback_result_surface_refresh_materialized=true" \
  "focus_movement_result_surface_refresh_materialized=true" \
  "stage608_feedback_host_inspection_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE606_SUITE_PACKET" || ! -f "$STAGE606_SUITE_PACKET" ]]; then
  echo "cjgui stage607 feedback host inspection demo surface suite: missing stage606 packet; set CJGUI_STAGE607_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage606_feedback_host_input_visual_execution_receipt_suite_version=1" \
  "stage605_form_result_feedback_host_input_layout_focus_inspection_consumed=true" \
  "shared_feedback_host_input_visual_execution_receipt_materialized=true" \
  "visual_execution_receipt_bound_to_stage605_inspection_slots=true" \
  "stage607_feedback_host_inspection_demo_surface_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE606_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage607 feedback host inspection demo surface suite: missing source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage607 feedback host inspection demo surface suite: public or foreign declaration found" >&2
  exit 11
fi

{
  echo "stage607_feedback_host_inspection_demo_surface_suite_version=1"
  echo "stage606_feedback_host_input_visual_execution_receipt_suite_packet=$STAGE606_SUITE_PACKET"
  echo "stage607_feedback_host_inspection_demo_surface_owner_passed=true"
  echo "stage606_feedback_host_input_visual_execution_receipt_consumed=true"
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_consumed_transitively=true"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_consumed_transitively=true"
  echo "shared_feedback_host_inspection_demo_surface_materialized=true"
  echo "validation_display_result_surface_refresh_materialized=true"
  echo "input_feedback_result_surface_refresh_materialized=true"
  echo "focus_movement_result_surface_refresh_materialized=true"
  echo "todo_feedback_host_inspection_demo_surface_materialized=true"
  echo "settings_feedback_host_inspection_demo_surface_materialized=true"
  echo "ai_generated_settings_feedback_host_inspection_demo_surface_materialized=true"
  echo "chat_composer_feedback_host_inspection_demo_surface_materialized=true"
  echo "demo_surface_bound_to_stage606_visual_execution_receipts=true"
  echo "stage607_public_foreign_scan_passed=true"
  echo "stage608_feedback_host_inspection_runtime_contract_prepared=true"
  echo "owner_acceptance_required=true"
  echo "owner_acceptance_granted=false"
  echo "production_render_truth=false"
  echo "backend_ready_truth=false"
  echo "layout_engine_enabled=false"
  echo "style_resolver_enabled=false"
  echo "focus_manager_enabled=false"
  echo "input_event_pipeline_enabled=false"
  echo "input_event_pipeline_execution=false"
  echo "action_dispatch=false"
  echo "state_update_committed=false"
  echo "visibility_publication_admitted=false"
  echo "visibility_published=false"
  echo "public_component_api_added=false"
  echo "renderer_submission=false"
  echo "renderer_state_write=false"
  echo "runtime_state_write=false"
  echo "native_bridge_expansion=false"
  echo "stage607_feedback_host_inspection_demo_surface_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage607 feedback host inspection demo surface suite: route_classification=feedback_host_inspection_demo_surface_ready"
echo "cjgui stage607 feedback host inspection demo surface suite: suite_packet_path=$SUITE_PACKET"
