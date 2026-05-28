#!/usr/bin/env zsh
#
# Focused suite for stage584. It consumes stage583 form commit previews and
# verifies a shared non-dispatching form commit cycle executor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE584_TMPDIR:-/private/tmp/cjgui-stage583-stage585/stage584}"
SUITE_PACKET="$TMP_DIR/stage584-form-commit-cycle-executor-suite.packet"
STAGE583_SUITE_PACKET="${CJGUI_STAGE584_INPUT_PACKET:-${CJGUI_STAGE583_FORM_INPUT_EVENT_COMMIT_PREVIEW_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage584_form_commit_cycle_executor_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage584_form_commit_cycle_executor.cj"
OWNER_LOG="$TMP_DIR/stage584-form-commit-cycle-executor-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage584 form commit cycle executor suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage584 form commit cycle executor suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage584 form commit cycle executor suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage584 form commit cycle executor suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage584 form commit cycle executor suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage583_form_input_event_commit_preview_consumed=true" \
  "shared_form_commit_cycle_executor_materialized=true" \
  "form_commit_action_intent_ledger_materialized=true" \
  "form_commit_state_delta_dry_run_ledger_materialized=true" \
  "form_commit_validation_refresh_ledger_materialized=true" \
  "form_commit_render_command_refresh_ledger_materialized=true" \
  "form_commit_rollback_preview_ledger_materialized=true" \
  "todo_form_commit_cycle_receipt_materialized=true" \
  "settings_form_commit_cycle_receipt_materialized=true" \
  "ai_generated_settings_form_commit_cycle_receipt_materialized=true" \
  "chat_composer_form_commit_cycle_receipt_materialized=true" \
  "form_commit_cycle_non_dispatching=true" \
  "form_commit_state_dry_run_only=true" \
  "stage585_form_commit_demo_runtime_surface_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE583_SUITE_PACKET" || ! -f "$STAGE583_SUITE_PACKET" ]]; then
  echo "cjgui stage584 form commit cycle executor suite: missing stage583 packet; set CJGUI_STAGE584_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage583_form_input_event_commit_preview_suite_version=1" \
  "stage582_form_demo_runtime_surface_contract_consumed=true" \
  "shared_form_input_commit_preview_adapter_materialized=true" \
  "normalized_form_commit_event_ledger_materialized=true" \
  "form_commit_rollback_preview_ledger_materialized=true" \
  "form_commit_owner_acceptance_ledger_materialized=true" \
  "chat_composer_form_commit_preview_event_materialized=true" \
  "stage584_form_commit_cycle_executor_prepared=true" \
  "input_event_pipeline_execution=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false" \
  "native_bridge_expansion=false"; do
  require_file_fact "$STAGE583_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage584 form commit cycle executor suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage584 form commit cycle executor suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage584 form commit cycle executor suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage584 form commit cycle executor suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage584_form_commit_cycle_executor_suite_version=1"
  echo "stage583_form_input_event_commit_preview_suite_packet=$STAGE583_SUITE_PACKET"
  echo "stage584_form_commit_cycle_executor_owner_passed=true"
  echo "stage583_form_input_event_commit_preview_consumed=true"
  echo "stage582_form_demo_runtime_surface_contract_consumed_transitively=true"
  echo "shared_form_commit_cycle_executor_materialized=true"
  echo "form_commit_action_intent_ledger_materialized=true"
  echo "form_commit_state_delta_dry_run_ledger_materialized=true"
  echo "form_commit_validation_refresh_ledger_materialized=true"
  echo "form_commit_render_command_refresh_ledger_materialized=true"
  echo "form_commit_rollback_preview_ledger_materialized=true"
  echo "todo_form_commit_cycle_receipt_materialized=true"
  echo "settings_form_commit_cycle_receipt_materialized=true"
  echo "ai_generated_settings_form_commit_cycle_receipt_materialized=true"
  echo "chat_composer_form_commit_cycle_receipt_materialized=true"
  echo "form_commit_cycle_bound_to_stage583_commit_preview=true"
  echo "form_commit_cycle_bound_to_stage582_runtime_surfaces=true"
  echo "form_commit_cycle_owner_local=true"
  echo "form_commit_cycle_non_dispatching=true"
  echo "form_commit_state_dry_run_only=true"
  echo "stage584_public_foreign_scan_passed=true"
  echo "stage584_forbidden_native_render_token_scan_passed=true"
  echo "stage584_protected_path_scan_passed=true"
  echo "stage585_form_commit_demo_runtime_surface_contract_prepared=true"
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
  echo "next_route=stage585_form_commit_demo_runtime_surface_contract_after_stage584"
  echo "stage584_form_commit_cycle_executor_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage584 form commit cycle executor suite: route_classification=form_commit_cycle_executor_ready"
echo "cjgui stage584 form commit cycle executor suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage584 form commit cycle executor suite: consumed_stage583=true"
echo "cjgui stage584 form commit cycle executor suite: visibility_published=false"
