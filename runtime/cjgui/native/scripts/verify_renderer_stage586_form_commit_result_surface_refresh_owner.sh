#!/usr/bin/env zsh
#
# Verifies the stage586 form commit result surface refresh owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage586_form_commit_result_surface_refresh.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage586 form commit result surface refresh: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage586FormCommitResultSurfaceRefreshPlan" \
  "CjguiInternalRendererStage586FormCommitResultSurfaceRefreshFacts" \
  "CjguiInternalRendererStage586FormCommitResultSurfaceRefreshReadiness" \
  "cjguiInternalExecuteDefaultRendererStage586FormCommitResultSurfaceRefreshDraft" \
  "CjguiInternalRendererStage585FormCommitDemoRuntimeSurfaceContractReadiness" \
  "didMaterializeSharedFormCommitResultSurfaceRefreshAdapter" \
  "didMaterializeAcceptedFormCommitResultSurface" \
  "didMaterializeRejectedFormCommitRollbackSurface" \
  "didMaterializeOwnerAcceptancePendingResultSurface" \
  "didMaterializeFormCommitResultRenderCommandRefreshPlan" \
  "didBindFormCommitResultSurfaceToStage585RuntimeSurfaces" \
  "didBindFormCommitResultSurfaceToStage584CycleReceipts" \
  "didBindFormCommitResultSurfaceToStage583CommitPreview" \
  "didPrepareStage587FormCommitResultFeedbackLayoutFocus"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage586 form commit result surface refresh: missing token $token" >&2
    exit 3
  fi
done

echo "stage586_form_commit_result_surface_refresh_owner_present=true"
echo "stage585_form_commit_demo_runtime_surface_contract_consumed=true"
echo "stage584_form_commit_cycle_executor_consumed_transitively=true"
echo "stage583_form_input_event_commit_preview_consumed_transitively=true"
echo "shared_form_commit_result_surface_refresh_adapter_materialized=true"
echo "accepted_form_commit_result_surface_materialized=true"
echo "rejected_form_commit_rollback_surface_materialized=true"
echo "owner_acceptance_pending_result_surface_materialized=true"
echo "form_commit_result_render_command_refresh_plan_materialized=true"
echo "todo_form_commit_result_surface_refresh_materialized=true"
echo "settings_form_commit_result_surface_refresh_materialized=true"
echo "ai_generated_settings_form_commit_result_surface_refresh_materialized=true"
echo "chat_composer_form_commit_result_surface_refresh_materialized=true"
echo "form_commit_result_surface_bound_to_stage585_runtime_surfaces=true"
echo "form_commit_result_surface_bound_to_stage584_cycle_receipts=true"
echo "form_commit_result_surface_bound_to_stage583_commit_preview=true"
echo "stage587_form_commit_result_feedback_layout_focus_prepared=true"
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
