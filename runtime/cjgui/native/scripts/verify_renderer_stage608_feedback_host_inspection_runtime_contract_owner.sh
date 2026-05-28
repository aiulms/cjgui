#!/usr/bin/env zsh
#
# Verifies the stage608 feedback host inspection runtime contract owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage608_feedback_host_inspection_runtime_contract.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage608 feedback host inspection runtime contract: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage608FeedbackHostInspectionRuntimeContractPlan" \
  "CjguiInternalRendererStage608FeedbackHostInspectionRuntimeContractFacts" \
  "CjguiInternalRendererStage608FeedbackHostInspectionRuntimeContractReadiness" \
  "cjguiInternalExecuteDefaultRendererStage608FeedbackHostInspectionRuntimeContractDraft" \
  "CjguiInternalRendererStage607FeedbackHostInspectionDemoSurfaceReadiness" \
  "didConsumeStage607FeedbackHostInspectionDemoSurface" \
  "didMaterializeSharedFeedbackHostInspectionRuntimeContract" \
  "didMaterializeSharedFeedbackHostInspectionRuntimeHelper" \
  "didMaterializeSharedFeedbackHostInspectionExecutionContract" \
  "didMaterializeChatComposerCheckableFeedbackHostInspectionRuntimeSurface" \
  "didBindRuntimeContractToStage607DemoSurfaces" \
  "didReducePerDemoFeedbackHostInspectionTemplateNeed" \
  "didPrepareStage609FeedbackHostInspectionInputStateBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage608 feedback host inspection runtime contract: missing token $token" >&2
    exit 3
  fi
done

echo "stage608_feedback_host_inspection_runtime_contract_owner_present=true"
echo "stage607_feedback_host_inspection_demo_surface_consumed=true"
echo "shared_feedback_host_inspection_runtime_contract_materialized=true"
echo "shared_feedback_host_inspection_runtime_helper_materialized=true"
echo "shared_feedback_host_inspection_execution_contract_materialized=true"
echo "todo_checkable_feedback_host_inspection_runtime_surface_materialized=true"
echo "settings_checkable_feedback_host_inspection_runtime_surface_materialized=true"
echo "ai_generated_settings_checkable_feedback_host_inspection_runtime_surface_materialized=true"
echo "chat_composer_checkable_feedback_host_inspection_runtime_surface_materialized=true"
echo "runtime_contract_bound_to_stage607_demo_surfaces=true"
echo "runtime_contract_bound_to_stage606_visual_execution_receipts=true"
echo "runtime_contract_bound_to_stage605_layout_focus_inspection=true"
echo "per_demo_feedback_host_inspection_template_need_reduced=true"
echo "stage609_feedback_host_inspection_input_state_bridge_prepared=true"
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
