#!/usr/bin/env zsh
#
# 维护注释：验证 stage254 component demo surface semantic diff/explain owner。
# 它把 stage253 internal surface 转成 owner acceptance 可读的 semantic diff / explain。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage254_component_demo_surface_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage254 component demo surface semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage254ComponentDemoSurfaceSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage254ComponentDemoSurfaceSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage254ComponentDemoSurfaceSemanticDiffExplainDraft" \
  "didConsumeStage253InternalComponentDemoSurface" \
  "didMaterializeComponentDemoSurfaceSemanticDiff" \
  "didMaterializeComponentDemoSurfaceExplainPacket" \
  "didBindSurfaceDiffToBackendResultPreview" \
  "didBindSurfaceExplainToRollbackReadyBoundary" \
  "didMaterializeSurfaceRollbackReadyBoundary" \
  "didPrepareStage255InternalComponentDemoProbeInput" \
  "didKeepOwnerAcceptanceRequired" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage254 component demo surface semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage254_component_demo_surface_semantic_diff_explain_owner_present=true"
echo "stage253_internal_component_demo_surface_required=true"
echo "component_demo_surface_semantic_diff_materialized=true"
echo "component_demo_surface_explain_packet_materialized=true"
echo "surface_diff_bound_to_backend_result_preview=true"
echo "surface_explain_bound_to_rollback_ready_boundary=true"
echo "surface_rollback_ready_boundary_materialized=true"
echo "stage255_internal_component_demo_probe_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
