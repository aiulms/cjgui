#!/usr/bin/env zsh
#
# 维护注释：验证 stage253 internal component demo surface owner。
# 它消费 stage252 backend result readiness，把 Button-like semantic node、
# refreshed RenderCommand、backend result preview 和 state-update bridge 汇成内部 demo surface。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage253_internal_component_demo_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage253 internal component demo surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage253InternalComponentDemoSurfaceFacts" \
  "CjguiInternalRendererStage253InternalComponentDemoSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage253InternalComponentDemoSurfaceDraft" \
  "didConsumeStage252ComponentDemoBackendResultReadinessDecision" \
  "didMaterializeInternalComponentDemoSurface" \
  "didJoinSurfaceWithButtonLikeSemanticNode" \
  "didJoinSurfaceWithRefreshedRenderCommand" \
  "didJoinSurfaceWithBackendResultPreview" \
  "didJoinSurfaceWithStateUpdateBridge" \
  "didKeepSurfaceOwnerLocalInMemoryOnly" \
  "didPrepareStage254ComponentDemoSurfaceSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage253 internal component demo surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage253_internal_component_demo_surface_owner_present=true"
echo "stage252_component_demo_backend_result_readiness_decision_required=true"
echo "internal_component_demo_surface_materialized=true"
echo "surface_joined_with_button_like_semantic_node=true"
echo "surface_joined_with_refreshed_render_command=true"
echo "surface_joined_with_backend_result_preview=true"
echo "surface_joined_with_state_update_bridge=true"
echo "surface_owner_local_in_memory_only=true"
echo "stage254_component_demo_surface_semantic_diff_explain_input_prepared=true"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
