#!/usr/bin/env zsh
#
# Focused suite for stage595. It consumes stage594 executor receipts and
# verifies checkable demo surface feedback receipts for four demos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE595_TMPDIR:-/private/tmp/cjgui-stage593-stage596/stage595}"
SUITE_PACKET="$TMP_DIR/stage595-form-result-host-feedback-demo-surface-receipt-suite.packet"
STAGE594_SUITE_PACKET="${CJGUI_STAGE595_INPUT_PACKET:-${CJGUI_STAGE594_FORM_RESULT_HOST_FEEDBACK_ACTION_STATE_RENDER_EXECUTOR_SUITE_PACKET:-/private/tmp/cjgui-stage593-stage596/stage594/stage594-form-result-host-feedback-action-state-render-executor-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage595_form_result_host_feedback_demo_surface_receipt_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage595_form_result_host_feedback_demo_surface_receipt.cj"
OWNER_LOG="$TMP_DIR/stage595-form-result-host-feedback-demo-surface-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage595 form result host feedback demo surface receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage595 form result host feedback demo surface receipt suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage594_form_result_host_feedback_action_state_render_executor_consumed=true" \
  "shared_form_result_host_feedback_demo_surface_receipt_materialized=true" \
  "host_feedback_demo_surface_refresh_ledger_materialized=true" \
  "host_feedback_validation_display_refresh_ledger_materialized=true" \
  "host_feedback_focus_movement_preview_ledger_materialized=true" \
  "host_feedback_input_display_ledger_materialized=true" \
  "todo_form_result_host_feedback_demo_surface_receipt_materialized=true" \
  "settings_form_result_host_feedback_demo_surface_receipt_materialized=true" \
  "ai_generated_settings_form_result_host_feedback_demo_surface_receipt_materialized=true" \
  "chat_composer_form_result_host_feedback_demo_surface_receipt_materialized=true" \
  "feedback_demo_surface_receipt_bound_to_stage594_receipts=true" \
  "stage596_form_result_host_feedback_cycle_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE594_SUITE_PACKET" || ! -f "$STAGE594_SUITE_PACKET" ]]; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: missing stage594 packet; set CJGUI_STAGE595_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage594_form_result_host_feedback_action_state_render_executor_suite_version=1" \
  "stage593_form_result_host_input_feedback_cycle_consumed=true" \
  "shared_form_result_host_feedback_action_state_render_executor_materialized=true" \
  "host_feedback_action_intent_ledger_materialized=true" \
  "host_feedback_state_delta_dry_run_ledger_materialized=true" \
  "host_feedback_render_command_refresh_ledger_materialized=true" \
  "chat_composer_form_result_host_feedback_action_state_render_receipt_materialized=true" \
  "stage595_form_result_host_feedback_demo_surface_receipt_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE594_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage595 form result host feedback demo surface receipt suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage595_form_result_host_feedback_demo_surface_receipt_suite_version=1"
  echo "stage594_form_result_host_feedback_action_state_render_executor_suite_packet=$STAGE594_SUITE_PACKET"
  echo "stage595_form_result_host_feedback_demo_surface_receipt_owner_passed=true"
  echo "stage594_form_result_host_feedback_action_state_render_executor_consumed=true"
  echo "stage593_form_result_host_input_feedback_cycle_consumed_transitively=true"
  echo "shared_form_result_host_feedback_demo_surface_receipt_materialized=true"
  echo "host_feedback_demo_surface_refresh_ledger_materialized=true"
  echo "host_feedback_validation_display_refresh_ledger_materialized=true"
  echo "host_feedback_focus_movement_preview_ledger_materialized=true"
  echo "host_feedback_input_display_ledger_materialized=true"
  echo "todo_form_result_host_feedback_demo_surface_receipt_materialized=true"
  echo "settings_form_result_host_feedback_demo_surface_receipt_materialized=true"
  echo "ai_generated_settings_form_result_host_feedback_demo_surface_receipt_materialized=true"
  echo "chat_composer_form_result_host_feedback_demo_surface_receipt_materialized=true"
  echo "feedback_demo_surface_receipt_bound_to_stage594_receipts=true"
  echo "feedback_demo_surface_receipt_bound_to_stage593_events=true"
  echo "stage595_public_foreign_scan_passed=true"
  echo "stage595_forbidden_native_render_token_scan_passed=true"
  echo "stage595_protected_path_scan_passed=true"
  echo "stage596_form_result_host_feedback_cycle_runtime_contract_prepared=true"
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
  echo "next_route=stage596_form_result_host_feedback_cycle_runtime_contract_after_stage595"
  echo "stage595_form_result_host_feedback_demo_surface_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage595 form result host feedback demo surface receipt suite: route_classification=form_result_host_feedback_demo_surface_receipt_ready"
echo "cjgui stage595 form result host feedback demo surface receipt suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage595 form result host feedback demo surface receipt suite: consumed_stage594=true"
echo "cjgui stage595 form result host feedback demo surface receipt suite: visibility_published=false"
