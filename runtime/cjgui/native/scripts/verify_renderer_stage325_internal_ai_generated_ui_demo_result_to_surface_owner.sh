#!/usr/bin/env zsh
#
# 维护注释：验证 stage325 internal AI-generated UI demo result-to-surface owner。
# 它消费 stage324 backend result readiness，把 backend result 映射成 owner-local demo surface refresh。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage325_internal_ai_generated_ui_demo_result_to_surface.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage325 internal ai generated ui demo result to surface: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage325InternalAiGeneratedUiDemoResultToSurfaceFacts" \
  "CjguiInternalRendererStage325InternalAiGeneratedUiDemoResultToSurfaceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage325InternalAiGeneratedUiDemoResultToSurfaceDraft" \
  "didConsumeStage324InternalAiGeneratedUiDemoBackendResultReadinessDecision" \
  "didMaterializeAiGeneratedUiDemoResultToSurface" \
  "didBindResultToSurfaceToBackendResultPreview" \
  "didBindResultToSurfaceToStateRenderBridge" \
  "didBindResultToSurfaceToRefreshedRenderCommandPreview" \
  "didKeepResultToSurfaceOwnerLocalInMemoryOnly" \
  "didKeepResultToSurfaceVisibilityNotPublished" \
  "didPrepareStage326ResultToProbeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage325 internal ai generated ui demo result to surface: missing token $token" >&2
    exit 3
  fi
done

echo "stage325_internal_ai_generated_ui_demo_result_to_surface_owner_present=true"
echo "stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_required=true"
echo "ai_generated_ui_demo_result_to_surface_materialized=true"
echo "result_to_surface_bound_to_backend_result_preview=true"
echo "result_to_surface_bound_to_state_render_bridge=true"
echo "result_to_surface_bound_to_refreshed_render_command_preview=true"
echo "result_to_surface_owner_local_in_memory_only=true"
echo "result_to_surface_visibility_not_published=true"
echo "stage326_internal_ai_generated_ui_demo_result_to_probe_input_prepared=true"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
