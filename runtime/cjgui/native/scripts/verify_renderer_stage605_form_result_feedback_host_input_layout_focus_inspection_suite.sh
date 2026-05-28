#!/usr/bin/env zsh
#
# Focused suite for stage605. It consumes stage604 host input runtime surfaces
# and verifies shared layout/focus inspection slots.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE605_TMPDIR:-/private/tmp/cjgui-stage605-stage608/stage605}"
SUITE_PACKET="$TMP_DIR/stage605-form-result-feedback-host-input-layout-focus-inspection-suite.packet"
STAGE604_SUITE_PACKET="${CJGUI_STAGE605_INPUT_PACKET:-${CJGUI_STAGE604_FORM_RESULT_FEEDBACK_HOST_INPUT_RUNTIME_SURFACE_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage601-stage604/stage604/stage604-form-result-feedback-host-input-runtime-surface-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage605_form_result_feedback_host_input_layout_focus_inspection_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage605_form_result_feedback_host_input_layout_focus_inspection.cj"
OWNER_LOG="$TMP_DIR/stage605-form-result-feedback-host-input-layout-focus-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage605 form result feedback host input layout focus inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage605 form result feedback host input layout focus inspection suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage604_form_result_feedback_host_input_runtime_surface_contract_consumed=true" \
  "shared_feedback_host_input_layout_inspection_ledger_materialized=true" \
  "shared_feedback_host_focus_inspection_ledger_materialized=true" \
  "validation_display_layout_slot_materialized=true" \
  "input_feedback_layout_slot_materialized=true" \
  "focus_transition_inspection_slot_materialized=true" \
  "stage606_feedback_host_input_visual_execution_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE604_SUITE_PACKET" || ! -f "$STAGE604_SUITE_PACKET" ]]; then
  echo "cjgui stage605 form result feedback host input layout focus inspection suite: missing stage604 packet; set CJGUI_STAGE605_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage604_form_result_feedback_host_input_runtime_surface_contract_suite_version=1" \
  "shared_form_result_feedback_host_input_runtime_surface_contract_materialized=true" \
  "shared_feedback_host_input_execution_receipt_contract_materialized=true" \
  "host_input_runtime_surface_contract_bound_to_stage603_cycle_receipts=true" \
  "stage605_form_result_feedback_host_input_layout_focus_inspection_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE604_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage605 form result feedback host input layout focus inspection suite: missing source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage605 form result feedback host input layout focus inspection suite: public or foreign declaration found" >&2
  exit 11
fi

{
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_suite_version=1"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_suite_packet=$STAGE604_SUITE_PACKET"
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_owner_passed=true"
  echo "stage604_form_result_feedback_host_input_runtime_surface_contract_consumed=true"
  echo "shared_feedback_host_input_layout_inspection_ledger_materialized=true"
  echo "shared_feedback_host_focus_inspection_ledger_materialized=true"
  echo "validation_display_layout_slot_materialized=true"
  echo "input_feedback_layout_slot_materialized=true"
  echo "focus_transition_inspection_slot_materialized=true"
  echo "todo_feedback_host_input_layout_focus_inspection_materialized=true"
  echo "settings_feedback_host_input_layout_focus_inspection_materialized=true"
  echo "ai_generated_settings_feedback_host_input_layout_focus_inspection_materialized=true"
  echo "chat_composer_feedback_host_input_layout_focus_inspection_materialized=true"
  echo "layout_focus_inspection_bound_to_stage604_runtime_surfaces=true"
  echo "stage605_public_foreign_scan_passed=true"
  echo "stage606_feedback_host_input_visual_execution_receipt_prepared=true"
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
  echo "stage605_form_result_feedback_host_input_layout_focus_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage605 form result feedback host input layout focus inspection suite: route_classification=feedback_host_input_layout_focus_inspection_ready"
echo "cjgui stage605 form result feedback host input layout focus inspection suite: suite_packet_path=$SUITE_PACKET"
