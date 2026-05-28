#!/usr/bin/env zsh
#
# Focused suite for stage594. It consumes stage593 normalized host feedback
# events and verifies a non-dispatching action/state/render executor receipt.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE594_TMPDIR:-/private/tmp/cjgui-stage593-stage596/stage594}"
SUITE_PACKET="$TMP_DIR/stage594-form-result-host-feedback-action-state-render-executor-suite.packet"
STAGE593_SUITE_PACKET="${CJGUI_STAGE594_INPUT_PACKET:-${CJGUI_STAGE593_FORM_RESULT_HOST_INPUT_FEEDBACK_CYCLE_SUITE_PACKET:-/private/tmp/cjgui-stage593-stage596/stage593/stage593-form-result-host-input-feedback-cycle-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage594_form_result_host_feedback_action_state_render_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage594_form_result_host_feedback_action_state_render_executor.cj"
OWNER_LOG="$TMP_DIR/stage594-form-result-host-feedback-action-state-render-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage594 form result host feedback action state render executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage594 form result host feedback action state render executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage594 form result host feedback action state render executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage594 form result host feedback action state render executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage594 form result host feedback action state render executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage593_form_result_host_input_feedback_cycle_consumed=true" \
  "shared_form_result_host_feedback_action_state_render_executor_materialized=true" \
  "host_feedback_action_intent_ledger_materialized=true" \
  "host_feedback_state_delta_dry_run_ledger_materialized=true" \
  "host_feedback_validation_refresh_ledger_materialized=true" \
  "host_feedback_render_command_refresh_ledger_materialized=true" \
  "todo_form_result_host_feedback_action_state_render_receipt_materialized=true" \
  "settings_form_result_host_feedback_action_state_render_receipt_materialized=true" \
  "ai_generated_settings_form_result_host_feedback_action_state_render_receipt_materialized=true" \
  "chat_composer_form_result_host_feedback_action_state_render_receipt_materialized=true" \
  "feedback_action_state_render_executor_bound_to_stage593_input_feedback_cycle=true" \
  "stage595_form_result_host_feedback_demo_surface_receipt_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE593_SUITE_PACKET" || ! -f "$STAGE593_SUITE_PACKET" ]]; then
  echo "cjgui stage594 form result host feedback action state render executor suite: missing stage593 packet; set CJGUI_STAGE594_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage593_form_result_host_input_feedback_cycle_suite_version=1" \
  "stage592_form_result_host_runtime_contract_consumed=true" \
  "shared_form_result_host_input_feedback_cycle_materialized=true" \
  "normalized_host_input_feedback_event_ledger_materialized=true" \
  "accepted_host_input_feedback_event_materialized=true" \
  "rejected_host_input_feedback_event_materialized=true" \
  "pending_host_input_feedback_event_materialized=true" \
  "chat_composer_form_result_host_input_feedback_cycle_materialized=true" \
  "stage594_form_result_host_feedback_action_state_render_executor_prepared=true" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE593_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage594 form result host feedback action state render executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage594 form result host feedback action state render executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage594 form result host feedback action state render executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage594 form result host feedback action state render executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage594_form_result_host_feedback_action_state_render_executor_suite_version=1"
  echo "stage593_form_result_host_input_feedback_cycle_suite_packet=$STAGE593_SUITE_PACKET"
  echo "stage594_form_result_host_feedback_action_state_render_executor_owner_passed=true"
  echo "stage593_form_result_host_input_feedback_cycle_consumed=true"
  echo "stage592_form_result_host_runtime_contract_consumed_transitively=true"
  echo "shared_form_result_host_feedback_action_state_render_executor_materialized=true"
  echo "host_feedback_action_intent_ledger_materialized=true"
  echo "host_feedback_state_delta_dry_run_ledger_materialized=true"
  echo "host_feedback_validation_refresh_ledger_materialized=true"
  echo "host_feedback_render_command_refresh_ledger_materialized=true"
  echo "todo_form_result_host_feedback_action_state_render_receipt_materialized=true"
  echo "settings_form_result_host_feedback_action_state_render_receipt_materialized=true"
  echo "ai_generated_settings_form_result_host_feedback_action_state_render_receipt_materialized=true"
  echo "chat_composer_form_result_host_feedback_action_state_render_receipt_materialized=true"
  echo "feedback_action_state_render_executor_bound_to_stage593_input_feedback_cycle=true"
  echo "feedback_action_state_render_executor_bound_to_stage592_runtime_surfaces=true"
  echo "stage594_public_foreign_scan_passed=true"
  echo "stage594_forbidden_native_render_token_scan_passed=true"
  echo "stage594_protected_path_scan_passed=true"
  echo "stage595_form_result_host_feedback_demo_surface_receipt_prepared=true"
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
  echo "next_route=stage595_form_result_host_feedback_demo_surface_receipt_after_stage594"
  echo "stage594_form_result_host_feedback_action_state_render_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage594 form result host feedback action state render executor suite: route_classification=form_result_host_feedback_action_state_render_executor_ready"
echo "cjgui stage594 form result host feedback action state render executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage594 form result host feedback action state render executor suite: consumed_stage593=true"
echo "cjgui stage594 form result host feedback action state render executor suite: visibility_published=false"
