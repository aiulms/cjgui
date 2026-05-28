#!/usr/bin/env zsh
#
# Focused suite for stage591. It consumes stage590 feedback routes and verifies
# a non-dispatching host execution receipt surface.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE591_TMPDIR:-/private/tmp/cjgui-stage589-stage592/stage591}"
SUITE_PACKET="$TMP_DIR/stage591-form-result-host-execution-receipt-suite.packet"
STAGE590_SUITE_PACKET="${CJGUI_STAGE591_INPUT_PACKET:-${CJGUI_STAGE590_FORM_RESULT_HOST_FEEDBACK_ADAPTER_SUITE_PACKET:-/private/tmp/cjgui-stage589-stage592/stage590/stage590-form-result-host-feedback-adapter-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage591_form_result_host_execution_receipt_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage591_form_result_host_execution_receipt.cj"
OWNER_LOG="$TMP_DIR/stage591-form-result-host-execution-receipt-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage591 form result host execution receipt suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage591 form result host execution receipt suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage591 form result host execution receipt suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage591 form result host execution receipt suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage591 form result host execution receipt suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage590_form_result_host_feedback_adapter_consumed=true" \
  "shared_form_result_host_execution_receipt_materialized=true" \
  "host_focus_transition_preview_ledger_materialized=true" \
  "host_input_feedback_preview_ledger_materialized=true" \
  "host_surface_invalidation_ledger_materialized=true" \
  "host_render_command_refresh_preview_ledger_materialized=true" \
  "todo_form_result_host_execution_receipt_materialized=true" \
  "settings_form_result_host_execution_receipt_materialized=true" \
  "ai_generated_settings_form_result_host_execution_receipt_materialized=true" \
  "chat_composer_form_result_host_execution_receipt_materialized=true" \
  "host_execution_receipt_bound_to_stage590_feedback_routes=true" \
  "stage592_form_result_host_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE590_SUITE_PACKET" || ! -f "$STAGE590_SUITE_PACKET" ]]; then
  echo "cjgui stage591 form result host execution receipt suite: missing stage590 packet; set CJGUI_STAGE591_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage590_form_result_host_feedback_adapter_suite_version=1" \
  "stage589_form_result_host_inspection_consumed=true" \
  "shared_form_result_host_feedback_adapter_materialized=true" \
  "accepted_host_feedback_route_materialized=true" \
  "rejected_host_validation_feedback_route_materialized=true" \
  "pending_owner_acceptance_host_feedback_route_materialized=true" \
  "chat_composer_form_result_host_feedback_event_materialized=true" \
  "stage591_form_result_host_execution_receipt_prepared=true" \
  "layout_engine_enabled=false" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE590_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage591 form result host execution receipt suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage591 form result host execution receipt suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage591 form result host execution receipt suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage591 form result host execution receipt suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage591_form_result_host_execution_receipt_suite_version=1"
  echo "stage590_form_result_host_feedback_adapter_suite_packet=$STAGE590_SUITE_PACKET"
  echo "stage591_form_result_host_execution_receipt_owner_passed=true"
  echo "stage590_form_result_host_feedback_adapter_consumed=true"
  echo "stage589_form_result_host_inspection_consumed_transitively=true"
  echo "shared_form_result_host_execution_receipt_materialized=true"
  echo "host_focus_transition_preview_ledger_materialized=true"
  echo "host_input_feedback_preview_ledger_materialized=true"
  echo "host_surface_invalidation_ledger_materialized=true"
  echo "host_render_command_refresh_preview_ledger_materialized=true"
  echo "todo_form_result_host_execution_receipt_materialized=true"
  echo "settings_form_result_host_execution_receipt_materialized=true"
  echo "ai_generated_settings_form_result_host_execution_receipt_materialized=true"
  echo "chat_composer_form_result_host_execution_receipt_materialized=true"
  echo "host_execution_receipt_bound_to_stage590_feedback_routes=true"
  echo "host_execution_receipt_bound_to_stage589_host_inspection=true"
  echo "stage591_public_foreign_scan_passed=true"
  echo "stage591_forbidden_native_render_token_scan_passed=true"
  echo "stage591_protected_path_scan_passed=true"
  echo "stage592_form_result_host_runtime_contract_prepared=true"
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
  echo "next_route=stage592_form_result_host_runtime_contract_after_stage591"
  echo "stage591_form_result_host_execution_receipt_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage591 form result host execution receipt suite: route_classification=form_result_host_execution_receipt_ready"
echo "cjgui stage591 form result host execution receipt suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage591 form result host execution receipt suite: consumed_stage590=true"
echo "cjgui stage591 form result host execution receipt suite: visibility_published=false"
