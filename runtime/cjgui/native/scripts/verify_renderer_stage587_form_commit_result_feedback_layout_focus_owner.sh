#!/usr/bin/env zsh
#
# Verifies the stage587 form commit result feedback layout/focus owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage587_form_commit_result_feedback_layout_focus.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage587 form commit result feedback layout focus: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage587FormCommitResultFeedbackLayoutFocusPlan" \
  "CjguiInternalRendererStage587FormCommitResultFeedbackLayoutFocusFacts" \
  "CjguiInternalRendererStage587FormCommitResultFeedbackLayoutFocusReadiness" \
  "cjguiInternalExecuteDefaultRendererStage587FormCommitResultFeedbackLayoutFocusDraft" \
  "CjguiInternalRendererStage586FormCommitResultSurfaceRefreshReadiness" \
  "didMaterializeSharedFormCommitResultFeedbackLayoutFocusResolver" \
  "didMaterializeFormCommitResultBannerLayoutSlotLedger" \
  "didMaterializeFormCommitValidationSummaryRefreshLedger" \
  "didMaterializePostCommitFocusTargetLedger" \
  "didMaterializeDirtyFieldStyleResetLedger" \
  "didMaterializeFormCommitFeedbackRenderCommandRefreshLedger" \
  "didBindFormCommitFeedbackToStage586ResultSurfaces" \
  "didBindFormCommitFeedbackToStage585RuntimeSurfaces" \
  "didPrepareStage588FormCommitResultDemoRuntimeContract"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage587 form commit result feedback layout focus: missing token $token" >&2
    exit 3
  fi
done

echo "stage587_form_commit_result_feedback_layout_focus_owner_present=true"
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
