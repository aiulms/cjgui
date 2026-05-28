#!/usr/bin/env zsh
#
# Focused suite for stage589. It consumes stage588 result runtime surfaces and
# verifies one shared demo-host inspection input model.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE589_TMPDIR:-/private/tmp/cjgui-stage589-stage592/stage589}"
SUITE_PACKET="$TMP_DIR/stage589-form-result-host-inspection-suite.packet"
STAGE588_SUITE_PACKET="${CJGUI_STAGE589_INPUT_PACKET:-${CJGUI_STAGE588_FORM_COMMIT_RESULT_DEMO_RUNTIME_CONTRACT_SUITE_PACKET:-/private/tmp/cjgui-stage586-stage588/stage588/stage588-form-commit-result-demo-runtime-contract-suite.packet}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage589_form_result_host_inspection_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage589_form_result_host_inspection.cj"
OWNER_LOG="$TMP_DIR/stage589-form-result-host-inspection-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage589 form result host inspection suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage589 form result host inspection suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage589 form result host inspection suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage589 form result host inspection suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage589 form result host inspection suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage588_form_commit_result_demo_runtime_contract_consumed=true" \
  "shared_form_result_host_inspection_contract_materialized=true" \
  "shared_form_result_host_inspection_helper_materialized=true" \
  "form_result_host_slot_ledger_materialized=true" \
  "form_result_host_validation_summary_slot_materialized=true" \
  "form_result_host_focus_handoff_slot_materialized=true" \
  "todo_form_result_host_inspection_input_materialized=true" \
  "settings_form_result_host_inspection_input_materialized=true" \
  "ai_generated_settings_form_result_host_inspection_input_materialized=true" \
  "chat_composer_form_result_host_inspection_input_materialized=true" \
  "form_result_host_inspection_bound_to_stage588_runtime_surfaces=true" \
  "per_demo_form_result_host_inspection_template_need_reduced=true" \
  "stage590_form_result_host_feedback_adapter_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE588_SUITE_PACKET" || ! -f "$STAGE588_SUITE_PACKET" ]]; then
  echo "cjgui stage589 form result host inspection suite: missing stage588 packet; set CJGUI_STAGE589_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage588_form_commit_result_demo_runtime_contract_suite_version=1" \
  "stage587_form_commit_result_feedback_layout_focus_consumed=true" \
  "shared_form_commit_result_demo_runtime_contract_materialized=true" \
  "shared_form_commit_result_demo_runtime_helper_materialized=true" \
  "shared_form_commit_result_execution_receipt_contract_materialized=true" \
  "chat_composer_checkable_form_commit_result_runtime_surface_materialized=true" \
  "stage589_component_runtime_form_result_host_inspection_prepared=true" \
  "layout_engine_enabled=false" \
  "style_resolver_enabled=false" \
  "focus_manager_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE588_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage589 form result host inspection suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage589 form result host inspection suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage589 form result host inspection suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage589 form result host inspection suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage589_form_result_host_inspection_suite_version=1"
  echo "stage588_form_commit_result_demo_runtime_contract_suite_packet=$STAGE588_SUITE_PACKET"
  echo "stage589_form_result_host_inspection_owner_passed=true"
  echo "stage588_form_commit_result_demo_runtime_contract_consumed=true"
  echo "stage587_form_commit_result_feedback_layout_focus_consumed_transitively=true"
  echo "shared_form_result_host_inspection_contract_materialized=true"
  echo "shared_form_result_host_inspection_helper_materialized=true"
  echo "form_result_host_slot_ledger_materialized=true"
  echo "form_result_host_validation_summary_slot_materialized=true"
  echo "form_result_host_focus_handoff_slot_materialized=true"
  echo "todo_form_result_host_inspection_input_materialized=true"
  echo "settings_form_result_host_inspection_input_materialized=true"
  echo "ai_generated_settings_form_result_host_inspection_input_materialized=true"
  echo "chat_composer_form_result_host_inspection_input_materialized=true"
  echo "form_result_host_inspection_bound_to_stage588_runtime_surfaces=true"
  echo "form_result_host_inspection_bound_to_stage587_feedback_receipts=true"
  echo "per_demo_form_result_host_inspection_template_need_reduced=true"
  echo "stage589_public_foreign_scan_passed=true"
  echo "stage589_forbidden_native_render_token_scan_passed=true"
  echo "stage589_protected_path_scan_passed=true"
  echo "stage590_form_result_host_feedback_adapter_prepared=true"
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
  echo "next_route=stage590_form_result_host_feedback_adapter_after_stage589"
  echo "stage589_form_result_host_inspection_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage589 form result host inspection suite: route_classification=form_result_host_inspection_ready"
echo "cjgui stage589 form result host inspection suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage589 form result host inspection suite: consumed_stage588=true"
echo "cjgui stage589 form result host inspection suite: visibility_published=false"
