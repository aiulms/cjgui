#!/usr/bin/env zsh
#
# Focused suite for stage637. It consumes stage636 runtime surfaces and verifies
# the shared result-surface layout/focus preview.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR="${CJGUI_STAGE637_TMPDIR:-/private/tmp/cjgui-stage637-stage640/stage637}"
SUITE_PACKET="$TMP_DIR/stage637-result-surface-layout-focus-preview-suite.packet"
STAGE636_SUITE_PACKET="${CJGUI_STAGE637_INPUT_PACKET:-${CJGUI_STAGE636_SHARED_FOCUS_VALIDATION_RESULT_SURFACE_INTERACTION_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage633-stage636/stage636/stage636-shared-focus-validation-result-surface-interaction-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage637_result_surface_layout_focus_preview_owner.sh"
OWNER_LOG="$TMP_DIR/stage637-result-surface-layout-focus-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage637 result surface layout focus preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

zsh -n "$OWNER_SCRIPT"
zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1

for fact in \
  "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed=true" \
  "shared_result_surface_interaction_layout_preview_materialized=true" \
  "shared_result_surface_interaction_focus_preview_materialized=true" \
  "chat_composer_result_surface_layout_focus_preview_materialized=true" \
  "stage638_result_surface_layout_focus_execution_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE636_SUITE_PACKET" || ! -f "$STAGE636_SUITE_PACKET" ]]; then
  echo "cjgui stage637 result surface layout focus preview suite: missing stage636 packet; set CJGUI_STAGE637_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_suite_version=1" \
  "shared_focus_validation_result_surface_interaction_runtime_contract_materialized=true" \
  "chat_composer_result_surface_interaction_runtime_surface_materialized=true" \
  "stage637_component_runtime_result_surface_interaction_layout_focus_preview_prepared=true" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE636_SUITE_PACKET" "$fact"
done

{
  echo "stage637_result_surface_layout_focus_preview_suite_version=1"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_suite_packet=$STAGE636_SUITE_PACKET"
  echo "stage637_result_surface_layout_focus_preview_owner_passed=true"
  echo "stage636_shared_focus_validation_result_surface_interaction_runtime_contract_consumed=true"
  echo "stage635_focus_validation_result_surface_state_render_refresh_consumed_transitively=true"
  echo "stage634_focus_validation_result_surface_action_state_adapter_consumed_transitively=true"
  echo "stage633_focus_validation_result_surface_interaction_bridge_consumed_transitively=true"
  echo "shared_result_surface_interaction_layout_preview_materialized=true"
  echo "shared_result_surface_interaction_focus_preview_materialized=true"
  echo "validation_display_layout_slot_materialized=true"
  echo "focus_ring_preview_slot_materialized=true"
  echo "input_feedback_affordance_slot_materialized=true"
  echo "todo_result_surface_layout_focus_preview_materialized=true"
  echo "settings_result_surface_layout_focus_preview_materialized=true"
  echo "ai_generated_settings_result_surface_layout_focus_preview_materialized=true"
  echo "chat_composer_result_surface_layout_focus_preview_materialized=true"
  echo "result_surface_layout_focus_preview_bound_to_stage636_runtime_surfaces=true"
  echo "stage638_result_surface_layout_focus_execution_receipt_prepared=true"
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
  echo "next_route=stage638_result_surface_layout_focus_execution_receipt_after_stage637"
  echo "stage637_result_surface_layout_focus_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage637 result surface layout focus preview suite: route_classification=result_surface_layout_focus_preview_ready"
echo "cjgui stage637 result surface layout focus preview suite: suite_packet_path=$SUITE_PACKET"
