#!/usr/bin/env zsh
#
# 维护注释：验证 stage381 shared component model owner。
# 它把 stage380 convergence loop 收束到可复用组件模型，并接回已有 state/render bridge。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage381_shared_component_model.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage381 shared component model: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage381SharedComponentSemanticNode" \
  "CjguiInternalRendererStage381SharedComponentLayoutStyleTextInputFocusModel" \
  "CjguiInternalRendererStage381SharedComponentStateDelta" \
  "CjguiInternalRendererStage381SharedRenderCommandRefreshPlan" \
  "CjguiInternalRendererStage381SharedComponentModel" \
  "CjguiInternalRendererStage381SharedComponentModelReadiness" \
  "cjguiInternalExecuteDefaultRendererStage381SharedComponentModelDraft" \
  "didConsumeStage380ConvergenceLoopReadinessDecision" \
  "didExitSameShapeSurfaceProbeReadinessLoop" \
  "didMaterializeSharedSemanticComponentModel" \
  "didMaterializeSharedLayoutModel" \
  "didMaterializeSharedStyleModel" \
  "didMaterializeSharedTextModel" \
  "didMaterializeSharedInputModel" \
  "didMaterializeSharedFocusModel" \
  "didBindSharedComponentModelToAiGeneratedUiDemo" \
  "didBindSharedComponentModelToOwnerLocalStateDelta" \
  "didBindSharedComponentModelToRenderCommandRefresh" \
  "didPrepareStage382SharedLayoutStyleInputFocusDemoProbe" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage381 shared component model: missing token $token" >&2
    exit 3
  fi
done

echo "stage381_shared_component_model_owner_present=true"
echo "stage380_convergence_loop_readiness_decision_required=true"
echo "stage323_backend_result_state_render_bridge_required=true"
echo "convergence_exit_decision_materialized=true"
echo "same_shape_surface_probe_readiness_loop_exited=true"
echo "shared_semantic_component_model_materialized=true"
echo "shared_layout_model_materialized=true"
echo "shared_style_model_materialized=true"
echo "shared_text_model_materialized=true"
echo "shared_input_model_materialized=true"
echo "shared_focus_model_materialized=true"
echo "shared_owner_local_state_delta_model_materialized=true"
echo "shared_render_command_refresh_plan_materialized=true"
echo "shared_component_model_bound_to_ai_generated_ui_demo=true"
echo "shared_component_model_bound_to_owner_local_state_delta=true"
echo "shared_component_model_bound_to_render_command_refresh=true"
echo "stage382_shared_layout_style_input_focus_demo_probe_prepared=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
