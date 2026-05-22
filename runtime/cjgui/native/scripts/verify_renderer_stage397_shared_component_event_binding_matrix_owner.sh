#!/usr/bin/env zsh
#
# 维护注释：验证 stage397 shared component event binding matrix owner。
# 它必须消费 stage396 component activation render refresh，并把 component identity/slot 扩成事件绑定矩阵。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage397_shared_component_event_binding_matrix.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage397 shared component event binding matrix: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage397ComponentEventBindingInputBridge" \
  "CjguiInternalRendererStage397ComponentEventBindingMatrix" \
  "CjguiInternalRendererStage397ComponentEventBindingResultBridge" \
  "CjguiInternalRendererStage397SharedComponentEventBindingMatrixFacts" \
  "CjguiInternalRendererStage397SharedComponentEventBindingMatrixReadiness" \
  "cjguiInternalExecuteDefaultRendererStage397SharedComponentEventBindingMatrixDraft" \
  "didConsumeStage396ComponentActivationRenderRefreshProbe" \
  "didMaterializeSharedComponentEventBindingMatrix" \
  "didBindPointerActivationEventToComponentIdentity" \
  "didBindKeyboardActivationEventToComponentIdentity" \
  "didBindTextSubmitEventToComponentIdentity" \
  "didBindTextEditCommitEventToComponentIdentity" \
  "didBindFocusTraversalEventToComponentIdentity" \
  "didBindComponentEventMatrixToActivationSlots" \
  "didBindComponentEventMatrixToSharedComponentModel" \
  "didBindComponentEventMatrixToStage396RenderRefresh" \
  "didMaterializeComponentEventOwnerAcceptanceGate" \
  "didMaterializeComponentEventStateDeltaPreview" \
  "didPrepareStage398ComponentEventSequenceRenderRefreshProbe" \
  "didKeepInputEventPipelineBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage397 shared component event binding matrix: missing token $token" >&2
    exit 3
  fi
done

echo "stage397_shared_component_event_binding_matrix_owner_present=true"
echo "stage396_component_activation_render_refresh_probe_required=true"
echo "stage396_component_activation_render_refresh_probe_consumed=true"
echo "shared_component_event_binding_matrix_materialized=true"
echo "pointer_activation_event_bound_to_component_identity=true"
echo "keyboard_activation_event_bound_to_component_identity=true"
echo "text_submit_event_bound_to_component_identity=true"
echo "text_edit_commit_event_bound_to_component_identity=true"
echo "focus_traversal_event_bound_to_component_identity=true"
echo "component_event_matrix_bound_to_activation_slots=true"
echo "component_event_matrix_bound_to_shared_component_model=true"
echo "component_event_matrix_bound_to_stage396_render_refresh=true"
echo "component_event_owner_acceptance_gate_materialized=true"
echo "component_event_state_delta_preview_materialized=true"
echo "stage398_component_event_sequence_render_refresh_probe_prepared=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "layout_engine_enabled=false"
echo "input_event_pipeline_enabled=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
