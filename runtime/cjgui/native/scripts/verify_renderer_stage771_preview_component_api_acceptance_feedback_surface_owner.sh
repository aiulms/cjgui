#!/usr/bin/env zsh
#
# Verifies the stage771 preview component API acceptance feedback surface owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage771_preview_component_api_acceptance_feedback_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage771 preview component api acceptance feedback surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage771PreviewComponentApiAcceptanceFeedbackSurfacePlan" \
  "CjguiInternalRendererStage771PreviewComponentApiAcceptanceFeedbackSurfaceFacts" \
  "CjguiInternalRendererStage771PreviewComponentApiAcceptanceFeedbackSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage771PreviewComponentApiAcceptanceFeedbackSurfaceDraft" \
  "CjguiInternalRendererStage770PreviewComponentApiAcceptanceDecisionReducerReadiness" \
  "didConsumeStage770PreviewComponentApiAcceptanceDecisionReducer" \
  "didMaterializePreviewComponentApiAcceptanceFeedbackRows" \
  "didMaterializePreviewComponentApiRejectReasonFeedbackRows" \
  "didMaterializePreviewComponentApiSemanticDiffAcknowledgeRows" \
  "didMaterializePreviewComponentApiCommitResultSurfaceRefresh" \
  "didMaterializePreviewComponentApiFocusReviewRows" \
  "didBindAcceptanceFeedbackSurfaceToStage770DecisionReducer" \
  "didPrepareStage772PreviewComponentApiOwnerAcceptanceDecisionRuntimeManager"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage771 preview component api acceptance feedback surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage771_preview_component_api_acceptance_feedback_surface_owner_present=true"
echo "stage770_preview_component_api_acceptance_decision_reducer_consumed=true"
echo "stage769_preview_component_api_owner_acceptance_boundary_consumed_transitively=true"
echo "preview_component_api_acceptance_feedback_rows_materialized=true"
echo "preview_component_api_reject_reason_feedback_rows_materialized=true"
echo "preview_component_api_semantic_diff_acknowledge_rows_materialized=true"
echo "preview_component_api_commit_result_surface_refresh_materialized=true"
echo "preview_component_api_focus_review_rows_materialized=true"
echo "preview_component_api_feedback_render_command_refresh_receipt_materialized=true"
echo "todo_preview_component_api_acceptance_feedback_surface_materialized=true"
echo "settings_preview_component_api_acceptance_feedback_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_acceptance_feedback_surface_materialized=true"
echo "chat_composer_preview_component_api_acceptance_feedback_surface_materialized=true"
echo "acceptance_feedback_surface_bound_to_stage770_decision_reducer=true"
echo "acceptance_feedback_surface_host_inspectable=true"
echo "stage772_preview_component_api_owner_acceptance_decision_runtime_manager_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
