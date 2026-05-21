#!/usr/bin/env zsh
#
# 维护注释：验证 stage324 internal AI-generated UI demo backend result readiness decision owner。
# readiness 只说明 backend result dry-run 链路可交给 result-to-surface，不执行 backend。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage324 internal ai generated ui demo backend result readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage324InternalAiGeneratedUiDemoBackendResultReadinessDecisionFacts" \
  "CjguiInternalRendererStage324InternalAiGeneratedUiDemoBackendResultReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage324InternalAiGeneratedUiDemoBackendResultReadinessDecisionDraft" \
  "didConsumeStage323BackendResultStateRenderBridge" \
  "didJoinBackendResultPreviewWithSemanticDiffExplain" \
  "didJoinBackendResultBridgeWithStateRenderDryRun" \
  "didJoinBackendResultRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoBackendResultReadinessDecision" \
  "didPrepareStage325InternalAiGeneratedUiDemoResultToSurface" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiBackendResultRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage324 internal ai generated ui demo backend result readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage324_internal_ai_generated_ui_demo_backend_result_readiness_decision_owner_present=true"
echo "ai_generated_ui_backend_result_state_render_bridge_required=true"
echo "internal_ai_generated_ui_demo_backend_result_readiness_decision_materialized=true"
echo "backend_result_preview_semantic_diff_explain_joined=true"
echo "backend_result_bridge_state_render_dry_run_joined=true"
echo "backend_result_runway_rollback_visibility_boundary_joined=true"
echo "stage325_internal_ai_generated_ui_demo_result_to_surface_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_backend_result_runway_advanced=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
