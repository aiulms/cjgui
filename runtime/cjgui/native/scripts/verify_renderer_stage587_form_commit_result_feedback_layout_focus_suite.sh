#!/usr/bin/env zsh
#
# Focused suite for stage587. It consumes stage586 result surfaces and verifies
# reusable post-commit feedback layout/style/focus receipts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_DIR="$(cd "$ROOT_DIR/../.." && pwd)"
TMP_DIR="${CJGUI_STAGE587_TMPDIR:-/private/tmp/cjgui-stage586-stage588/stage587}"
SUITE_PACKET="$TMP_DIR/stage587-form-commit-result-feedback-layout-focus-suite.packet"
STAGE586_SUITE_PACKET="${CJGUI_STAGE587_INPUT_PACKET:-${CJGUI_STAGE586_FORM_COMMIT_RESULT_SURFACE_REFRESH_SUITE_PACKET:-}}"
OWNER_SCRIPT="$SCRIPT_DIR/verify_renderer_stage587_form_commit_result_feedback_layout_focus_owner.sh"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage587_form_commit_result_feedback_layout_focus.cj"
OWNER_LOG="$TMP_DIR/stage587-form-commit-result-feedback-layout-focus-owner.log"

mkdir -p "$TMP_DIR"
: > "$SUITE_PACKET"

require_file_fact() {
  local file="$1"
  local fact="$2"
  if ! grep -F "$fact" "$file" >/dev/null 2>&1; then
    echo "cjgui stage587 form commit result feedback layout focus suite: missing fact $fact in $file" >&2
    exit 5
  fi
}

if [[ ! -x "$OWNER_SCRIPT" ]]; then
  echo "cjgui stage587 form commit result feedback layout focus suite: missing executable owner script $OWNER_SCRIPT" >&2
  exit 3
fi
if ! zsh -n "$OWNER_SCRIPT"; then
  echo "cjgui stage587 form commit result feedback layout focus suite: syntax check failed $OWNER_SCRIPT" >&2
  exit 4
fi
if ! zsh "$OWNER_SCRIPT" > "$OWNER_LOG" 2>&1; then
  echo "cjgui stage587 form commit result feedback layout focus suite: owner probe failed $OWNER_SCRIPT" >&2
  echo "cjgui stage587 form commit result feedback layout focus suite: log=$OWNER_LOG" >&2
  exit 6
fi

for fact in \
  "stage586_form_commit_result_surface_refresh_consumed=true" \
  "shared_form_commit_result_feedback_layout_focus_resolver_materialized=true" \
  "form_commit_result_banner_layout_slot_ledger_materialized=true" \
  "form_commit_validation_summary_refresh_ledger_materialized=true" \
  "post_commit_focus_target_ledger_materialized=true" \
  "dirty_field_style_reset_ledger_materialized=true" \
  "form_commit_feedback_render_command_refresh_ledger_materialized=true" \
  "todo_form_commit_feedback_receipt_materialized=true" \
  "settings_form_commit_feedback_receipt_materialized=true" \
  "ai_generated_settings_form_commit_feedback_receipt_materialized=true" \
  "chat_composer_form_commit_feedback_receipt_materialized=true" \
  "stage588_form_commit_result_demo_runtime_contract_prepared=true"; do
  require_file_fact "$OWNER_LOG" "$fact"
done

if [[ -z "$STAGE586_SUITE_PACKET" || ! -f "$STAGE586_SUITE_PACKET" ]]; then
  echo "cjgui stage587 form commit result feedback layout focus suite: missing stage586 packet; set CJGUI_STAGE587_INPUT_PACKET" >&2
  exit 7
fi

for fact in \
  "stage586_form_commit_result_surface_refresh_suite_version=1" \
  "stage585_form_commit_demo_runtime_surface_contract_consumed=true" \
  "shared_form_commit_result_surface_refresh_adapter_materialized=true" \
  "accepted_form_commit_result_surface_materialized=true" \
  "rejected_form_commit_rollback_surface_materialized=true" \
  "owner_acceptance_pending_result_surface_materialized=true" \
  "form_commit_result_render_command_refresh_plan_materialized=true" \
  "stage587_form_commit_result_feedback_layout_focus_prepared=true" \
  "layout_engine_enabled=false" \
  "style_resolver_enabled=false" \
  "focus_manager_enabled=false" \
  "action_dispatch=false" \
  "state_update_committed=false" \
  "renderer_submission=false" \
  "renderer_state_write=false" \
  "runtime_state_write=false"; do
  require_file_fact "$STAGE586_SUITE_PACKET" "$fact"
done

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage587 form commit result feedback layout focus suite: missing owner source $OWNER_SRC" >&2
  exit 10
fi
if grep -E 'foreign[[:space:]]+func|public[[:space:]]+(func|struct|class|enum|let|var)' "$OWNER_SRC" >/dev/null 2>&1; then
  echo "cjgui stage587 form commit result feedback layout focus suite: public or foreign declaration found in $OWNER_SRC" >&2
  exit 11
fi
if sed '/^[[:space:]]*\/\//d;/^[[:space:]]*\/\*/d;/^[[:space:]]*\*/d' "$OWNER_SRC" \
  | grep -E 'sharedApplication|setActivationPolicy|activateIgnoringOtherApps|makeKeyAndOrderFront|orderFront|nextDrawable|renderCommandEncoder|setRenderPipelineState|setVertexBuffer|drawPrimitives|drawIndexedPrimitives|presentDrawable|present\]|commit\]|waitUntilCompleted|screencapture|CGWindow|CGDisplay|CGImage|CGBitmapContext|NSWindow[[:space:]]*\*|NSView[[:space:]]*\*|CAMetalLayer[[:space:]]*\*|MTLCommandQueue|MTLCommandBuffer|MTLRenderCommandEncoder|MTLRenderPipelineState|MTLBuffer' >/dev/null 2>&1; then
  echo "cjgui stage587 form commit result feedback layout focus suite: forbidden native/render token found in $OWNER_SRC" >&2
  exit 12
fi
if git -C "$REPO_DIR" diff --name-only -- runtime/cjgui/cjpm.toml runtime/cjgui/src/runtime_state.cj runtime/cjgui/native/cjgui_native_bridge.h runtime/cjgui/native/cjgui_native_bridge.m | grep . >/dev/null 2>&1; then
  echo "cjgui stage587 form commit result feedback layout focus suite: protected production bridge/state path modified" >&2
  exit 13
fi

{
  echo "stage587_form_commit_result_feedback_layout_focus_suite_version=1"
  echo "stage586_form_commit_result_surface_refresh_suite_packet=$STAGE586_SUITE_PACKET"
  echo "stage587_form_commit_result_feedback_layout_focus_owner_passed=true"
  echo "stage586_form_commit_result_surface_refresh_consumed=true"
  echo "stage585_form_commit_demo_runtime_surface_contract_consumed_transitively=true"
  echo "shared_form_commit_result_feedback_layout_focus_resolver_materialized=true"
  echo "form_commit_result_banner_layout_slot_ledger_materialized=true"
  echo "form_commit_validation_summary_refresh_ledger_materialized=true"
  echo "post_commit_focus_target_ledger_materialized=true"
  echo "dirty_field_style_reset_ledger_materialized=true"
  echo "form_commit_feedback_render_command_refresh_ledger_materialized=true"
  echo "todo_form_commit_feedback_receipt_materialized=true"
  echo "settings_form_commit_feedback_receipt_materialized=true"
  echo "ai_generated_settings_form_commit_feedback_receipt_materialized=true"
  echo "chat_composer_form_commit_feedback_receipt_materialized=true"
  echo "form_commit_feedback_bound_to_stage586_result_surfaces=true"
  echo "form_commit_feedback_bound_to_stage585_runtime_surfaces=true"
  echo "stage587_public_foreign_scan_passed=true"
  echo "stage587_forbidden_native_render_token_scan_passed=true"
  echo "stage587_protected_path_scan_passed=true"
  echo "stage588_form_commit_result_demo_runtime_contract_prepared=true"
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
  echo "next_route=stage588_form_commit_result_demo_runtime_contract_after_stage587"
  echo "stage587_form_commit_result_feedback_layout_focus_suite_passed=true"
} > "$SUITE_PACKET"

echo "cjgui stage587 form commit result feedback layout focus suite: route_classification=form_commit_result_feedback_layout_focus_ready"
echo "cjgui stage587 form commit result feedback layout focus suite: suite_packet_path=$SUITE_PACKET"
echo "cjgui stage587 form commit result feedback layout focus suite: consumed_stage586=true"
echo "cjgui stage587 form commit result feedback layout focus suite: visibility_published=false"
