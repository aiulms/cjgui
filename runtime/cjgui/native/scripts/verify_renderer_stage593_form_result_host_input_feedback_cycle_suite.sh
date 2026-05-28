#!/usr/bin/env zsh
#
# Focused suite for stage593. It consumes stage592 host runtime surfaces and
# verifies one normalized, owner-local host input feedback cycle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE593_TMPDIR:-/private/tmp/cjgui-stage593-stage596/stage593}"
SUITE_PACKET="$TMP_DIR/stage593-form-result-host-input-feedback-cycle-suite.packet"
STAGE592_SUITE_PACKET="${CJGUI_STAGE593_INPUT_PACKET:-${CJGUI_STAGE592_FORM_RESULT_HOST_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage589-stage592/stage592/stage592-form-result-host-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage593_form_result_host_input_feedback_cycle_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage593_form_result_host_input_feedback_cycle.cj"
OWNER_LOG="$TMP_DIR/stage593-form-result-host-input-feedback-cycle-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage593 form result host input feedback cycle suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage593 form result host input feedback cycle suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage593 form result host input feedback cycle suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage593 form result host input feedback cycle suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage593 form result host input feedback cycle suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage592_form_result_host_runtime_contract_consumed=true" \
  "shared_form_result_host_input_feedback_cycle_materialized=true" \
  "normalized_host_input_feedback_event_ledger_materialized=true" \
  "accepted_host_input_feedback_event_materialized=true" \
  "rejected_host_input_feedback_event_materialized=true" \
  "pending_host_input_feedback_event_materialized=true" \
  "todo_form_result_host_input_feedback_cycle_materialized=true" \
  "settings_form_result_host_input_feedback_cycle_materialized=true" \
  "ai_generated_settings_form_result_host_input_feedback_cycle_materialized=true" \
  "chat_composer_form_result_host_input_feedback_cycle_materialized=true" \
  "host_input_feedback_cycle_bound_to_stage592_runtime_surfaces=true" \
  "stage594_form_result_host_feedback_action_state_render_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE592_SUITE_PACKET" || ! -f "$STAGE592_SUITE_PACKET" ]]; then
  echo "cjgui stage593 form result host input feedback cycle suite: missing stage592 packet; set CJGUI_STAGE593_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage592_form_result_host_runtime_contract_suite_version=1" \
  "stage591_form_result_host_execution_receipt_consumed=true" \
  "shared_form_result_host_runtime_contract_materialized=true" \
  "shared_form_result_host_runtime_helper_materialized=true" \
  "shared_form_result_host_runtime_execution_contract_materialized=true" \
  "chat_composer_checkable_form_result_host_runtime_surface_materialized=true" \
  "stage593_form_result_host_input_feedback_cycle_prepared=true" \
  "layout_engine_enabled=false" \
  "style_resolver_enabled=false" \
  "focus_manager_enabled=false" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE592_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage593 form result host input feedback cycle suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage593 form result host input feedback cycle suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage593 form result host input feedback cycle suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage593 form result host input feedback cycle suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage593_form_result_host_input_feedback_cycle_suite_version=1"
  echo "stage592_form_result_host_runtime_contract_suite_packet=$STAGE592_SUITE_PACKET"
  echo "stage593_form_result_host_input_feedback_cycle_owner_passed=true"
  echo "stage592_form_result_host_runtime_contract_consumed=true"
  echo "stage591_form_result_host_execution_receipt_consumed_transitively=true"
  echo "shared_form_result_host_input_feedback_cycle_materialized=true"
  echo "normalized_host_input_feedback_event_ledger_materialized=true"
  echo "accepted_host_input_feedback_event_materialized=true"
  echo "rejected_host_input_feedback_event_materialized=true"
  echo "pending_host_input_feedback_event_materialized=true"
  echo "todo_form_result_host_input_feedback_cycle_materialized=true"
  echo "settings_form_result_host_input_feedback_cycle_materialized=true"
  echo "ai_generated_settings_form_result_host_input_feedback_cycle_materialized=true"
  echo "chat_composer_form_result_host_input_feedback_cycle_materialized=true"
  echo "host_input_feedback_cycle_bound_to_stage592_runtime_surfaces=true"
  echo "host_input_feedback_cycle_bound_to_stage591_execution_receipts=true"
  echo "stage593_public_foreign_scan_passed=true"
  echo "stage593_forbidden_native_render_token_scan_passed=true"
  echo "stage593_protected_path_scan_passed=true"
  echo "stage594_form_result_host_feedback_action_state_render_executor_prepared=true"
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
  echo "next_route=stage594_form_result_host_feedback_action_state_render_executor_after_stage593"
  echo "stage593_form_result_host_input_feedback_cycle_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage593 form result host input feedback cycle suite: route_classification=form_result_host_input_feedback_cycle_ready"
echo "cjgui stage593 form result host input feedback cycle suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage593 form result host input feedback cycle suite: consumed_stage592=true"
echo "cjgui stage593 form result host input feedback cycle suite: visibility_published=false"
