#!/usr/bin/env zsh
#
# Focused suite for stage583. It consumes stage582 form runtime surfaces and
# verifies one shared form input commit preview adapter across demos.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE583_TMPDIR:-/private/tmp/cjgui-stage583-stage585/stage583}"
SUITE_PACKET="$TMP_DIR/stage583-form-input-event-commit-preview-suite.packet"
STAGE582_SUITE_PACKET="${CJGUI_STAGE583_INPUT_PACKET:-${CJGUI_STAGE582_FORM_DEMO_RUNTIME_SURFACE_CONTRACT_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage583_form_input_event_commit_preview_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage583_form_input_event_commit_preview.cj"
OWNER_LOG="$TMP_DIR/stage583-form-input-event-commit-preview-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage583 form input event commit preview suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage583 form input event commit preview suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage583 form input event commit preview suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage583 form input event commit preview suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage583 form input event commit preview suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage582_form_demo_runtime_surface_contract_consumed=true" \
  "shared_form_input_commit_preview_adapter_materialized=true" \
  "normalized_form_commit_event_ledger_materialized=true" \
  "form_commit_rollback_preview_ledger_materialized=true" \
  "form_commit_owner_acceptance_ledger_materialized=true" \
  "todo_form_commit_preview_event_materialized=true" \
  "settings_form_commit_preview_event_materialized=true" \
  "ai_generated_settings_form_commit_preview_event_materialized=true" \
  "chat_composer_form_commit_preview_event_materialized=true" \
  "form_input_commit_preview_bound_to_stage582_runtime_surfaces=true" \
  "stage584_form_commit_cycle_executor_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE582_SUITE_PACKET" || ! -f "$STAGE582_SUITE_PACKET" ]]; then
  echo "cjgui stage583 form input event commit preview suite: missing stage582 packet; set CJGUI_STAGE583_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage582_form_demo_runtime_surface_contract_suite_version=1" \
  "stage581_form_summary_focus_render_executor_consumed=true" \
  "shared_form_demo_runtime_surface_contract_materialized=true" \
  "shared_form_demo_runtime_surface_helper_materialized=true" \
  "shared_form_execution_receipt_contract_materialized=true" \
  "todo_checkable_form_runtime_surface_materialized=true" \
  "settings_checkable_form_runtime_surface_materialized=true" \
  "ai_generated_settings_checkable_form_runtime_surface_materialized=true" \
  "chat_composer_checkable_form_runtime_surface_materialized=true" \
  "stage583_component_runtime_form_input_event_commit_preview_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE582_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage583 form input event commit preview suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage583 form input event commit preview suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage583 form input event commit preview suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage583 form input event commit preview suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage583_form_input_event_commit_preview_suite_version=1"
  echo "stage582_form_demo_runtime_surface_contract_suite_packet=$STAGE582_SUITE_PACKET"
  echo "stage583_form_input_event_commit_preview_owner_passed=true"
  echo "stage582_form_demo_runtime_surface_contract_consumed=true"
  echo "stage581_form_summary_focus_render_executor_consumed_transitively=true"
  echo "shared_form_input_commit_preview_adapter_materialized=true"
  echo "normalized_form_commit_event_ledger_materialized=true"
  echo "form_commit_rollback_preview_ledger_materialized=true"
  echo "form_commit_owner_acceptance_ledger_materialized=true"
  echo "todo_form_commit_preview_event_materialized=true"
  echo "settings_form_commit_preview_event_materialized=true"
  echo "ai_generated_settings_form_commit_preview_event_materialized=true"
  echo "chat_composer_form_commit_preview_event_materialized=true"
  echo "form_input_commit_preview_bound_to_stage582_runtime_surfaces=true"
  echo "form_input_commit_preview_bound_to_stage581_summary_receipts=true"
  echo "form_input_commit_preview_owner_local=true"
  echo "stage583_public_foreign_scan_passed=true"
  echo "stage583_forbidden_native_render_token_scan_passed=true"
  echo "stage583_protected_path_scan_passed=true"
  echo "stage584_form_commit_cycle_executor_prepared=true"
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
  echo "next_route=stage584_form_commit_cycle_executor_after_stage583"
  echo "stage583_form_input_event_commit_preview_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage583 form input event commit preview suite: route_classification=form_input_commit_preview_ready"
echo "cjgui stage583 form input event commit preview suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage583 form input event commit preview suite: consumed_stage582=true"
echo "cjgui stage583 form input event commit preview suite: visibility_published=false"
