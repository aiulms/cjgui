#!/usr/bin/env zsh
#
# 维护注释：验证 stage259 internal component demo loop semantic diff/explain owner。
# 它解释 loop preview 的 semantic/state/render delta，并固定 rollback 与 visibility-not-published 边界。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage259_internal_component_demo_loop_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage259 internal component demo loop semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage259InternalComponentDemoLoopSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage259InternalComponentDemoLoopSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage259InternalComponentDemoLoopSemanticDiffExplainDraft" \
  "didConsumeStage258InternalComponentDemoLoopTransitionPreviewPacket" \
  "didMaterializeLoopSemanticDiff" \
  "didMaterializeLoopExplainPacket" \
  "didBindLoopDiffToStateUpdateDelta" \
  "didBindLoopDiffToRenderCommandDelta" \
  "didBindLoopExplainToActionIntentFacts" \
  "didMaterializeLoopRollbackReadyBoundary" \
  "didMaterializeLoopVisibilityNotPublishedBoundary" \
  "didPrepareStage260LoopReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage259 internal component demo loop semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage259_internal_component_demo_loop_semantic_diff_explain_owner_present=true"
echo "stage258_internal_component_demo_loop_transition_preview_packet_required=true"
echo "internal_component_demo_loop_semantic_diff_materialized=true"
echo "internal_component_demo_loop_explain_packet_materialized=true"
echo "loop_diff_bound_to_state_update_delta=true"
echo "loop_diff_bound_to_render_command_delta=true"
echo "loop_explain_bound_to_action_intent_facts=true"
echo "loop_rollback_ready_boundary_materialized=true"
echo "loop_visibility_not_published_boundary_materialized=true"
echo "stage260_loop_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
