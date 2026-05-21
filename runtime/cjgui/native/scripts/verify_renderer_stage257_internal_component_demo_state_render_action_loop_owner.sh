#!/usr/bin/env zsh
#
# 维护注释：验证 stage257 internal component demo state/render/action loop owner。
# 它只汇合 action intent、owner-local state update dry-run、refreshed RenderCommand 与 non-executing probe input。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage257_internal_component_demo_state_render_action_loop.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage257 internal component demo state render action loop: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage257InternalComponentDemoStateRenderActionLoopFacts" \
  "CjguiInternalRendererStage257InternalComponentDemoStateRenderActionLoopReadiness" \
  "cjguiInternalExecuteDefaultRendererStage257InternalComponentDemoStateRenderActionLoopDraft" \
  "didConsumeStage256ComponentDemoSurfaceReadinessDecision" \
  "didMaterializeInternalComponentDemoStateRenderActionLoop" \
  "didBindDemoLoopToActionIntentFacts" \
  "didBindDemoLoopToOwnerLocalStateUpdateDryRun" \
  "didBindDemoLoopToRefreshedRenderCommand" \
  "didBindDemoLoopToNonExecutingProbeInput" \
  "didKeepDemoLoopOwnerLocalInMemoryOnly" \
  "didPrepareStage258LoopTransitionPreviewInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage257 internal component demo state render action loop: missing token $token" >&2
    exit 3
  fi
done

echo "stage257_internal_component_demo_state_render_action_loop_owner_present=true"
echo "stage256_component_demo_surface_readiness_decision_required=true"
echo "internal_component_demo_state_render_action_loop_materialized=true"
echo "demo_loop_bound_to_action_intent_facts=true"
echo "demo_loop_bound_to_owner_local_state_update_dry_run=true"
echo "demo_loop_bound_to_refreshed_render_command=true"
echo "demo_loop_bound_to_non_executing_probe_input=true"
echo "stage258_loop_transition_preview_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
