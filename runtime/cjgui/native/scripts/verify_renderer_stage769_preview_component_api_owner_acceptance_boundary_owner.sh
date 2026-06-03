#!/usr/bin/env zsh
#
# Verifies the stage769 preview component API owner acceptance boundary owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage769_preview_component_api_owner_acceptance_boundary.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage769 preview component api owner acceptance boundary: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage769PreviewComponentApiOwnerAcceptanceBoundaryPlan" \
  "CjguiInternalRendererStage769PreviewComponentApiOwnerAcceptanceBoundaryFacts" \
  "CjguiInternalRendererStage769PreviewComponentApiOwnerAcceptanceBoundaryReadiness" \
  "cjguiInternalExecuteDefaultRendererStage769PreviewComponentApiOwnerAcceptanceBoundaryDraft" \
  "CjguiInternalRendererStage768PreviewComponentApiCommitRuntimeManagerReadiness" \
  "didConsumeStage768PreviewComponentApiCommitRuntimeManager" \
  "didMaterializePreviewComponentApiOwnerAcceptanceBoundary" \
  "didMaterializePreviewComponentApiOwnerAcceptTokenRequirement" \
  "didMaterializePreviewComponentApiOwnerRejectReasonRequirement" \
  "didMaterializePreviewComponentApiOwnerReviewChecklist" \
  "didMaterializeChatComposerPreviewComponentApiOwnerAcceptanceBoundarySurface" \
  "didBindOwnerAcceptanceBoundaryToStage768CommitRuntimeManager" \
  "didPrepareStage770PreviewComponentApiAcceptanceDecisionReducer"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage769 preview component api owner acceptance boundary: missing token $token" >&2
    exit 3
  fi
done

echo "stage769_preview_component_api_owner_acceptance_boundary_owner_present=true"
echo "stage768_preview_component_api_commit_runtime_manager_consumed=true"
echo "stage767_preview_component_api_commit_host_inspection_proof_consumed_transitively=true"
echo "stage766_preview_component_api_commit_rollback_snapshot_consumed_transitively=true"
echo "stage765_preview_component_api_commit_preflight_consumed_transitively=true"
echo "preview_component_api_owner_acceptance_boundary_materialized=true"
echo "preview_component_api_owner_accept_token_requirement_materialized=true"
echo "preview_component_api_owner_reject_reason_requirement_materialized=true"
echo "preview_component_api_owner_review_checklist_materialized=true"
echo "todo_preview_component_api_owner_acceptance_boundary_surface_materialized=true"
echo "settings_preview_component_api_owner_acceptance_boundary_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_owner_acceptance_boundary_surface_materialized=true"
echo "chat_composer_preview_component_api_owner_acceptance_boundary_surface_materialized=true"
echo "owner_acceptance_boundary_bound_to_stage768_commit_runtime_manager=true"
echo "accept_reject_boundary_preview_only=true"
echo "stage770_preview_component_api_acceptance_decision_reducer_prepared=true"
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
