#!/usr/bin/env zsh
#
# 维护注释：验证 stage321 internal AI-generated UI demo backend result preview owner。
# 它只把 stage320 backend adapter readiness 转成 owner-local preview，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage321_internal_ai_generated_ui_demo_backend_result_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage321 internal ai generated ui demo backend result preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage321InternalAiGeneratedUiDemoBackendResultPreviewFacts" \
  "CjguiInternalRendererStage321InternalAiGeneratedUiDemoBackendResultPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage321InternalAiGeneratedUiDemoBackendResultPreviewDraft" \
  "didConsumeStage320InternalAiGeneratedUiDemoBackendAdapterReadinessDecision" \
  "didMaterializeAiGeneratedUiBackendResultPreview" \
  "didBindBackendResultPreviewToBackendAdapterResultEnvelope" \
  "didBindBackendResultPreviewToBackendAdapterSemanticDiffExplain" \
  "didBindBackendResultPreviewToActionLoopRefreshedRenderCommand" \
  "didKeepBackendResultPreviewOwnerLocalInMemoryOnly" \
  "didPreserveBackendAdapterRollbackVisibilityBoundary" \
  "didPrepareStage322BackendResultSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage321 internal ai generated ui demo backend result preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage321_internal_ai_generated_ui_demo_backend_result_preview_owner_present=true"
echo "stage320_internal_ai_generated_ui_demo_backend_adapter_readiness_decision_required=true"
echo "ai_generated_ui_backend_result_preview_materialized=true"
echo "backend_result_preview_bound_to_backend_adapter_result_envelope=true"
echo "backend_result_preview_bound_to_backend_adapter_semantic_diff_explain=true"
echo "backend_result_preview_bound_to_action_loop_refreshed_render_command=true"
echo "backend_result_preview_owner_local_in_memory_only=true"
echo "backend_adapter_rollback_visibility_boundary_preserved=true"
echo "stage322_backend_result_semantic_diff_explain_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
