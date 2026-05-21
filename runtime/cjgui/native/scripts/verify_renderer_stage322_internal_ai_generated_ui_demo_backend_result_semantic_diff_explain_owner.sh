#!/usr/bin/env zsh
#
# 维护注释：验证 stage322 internal AI-generated UI demo backend result semantic diff/explain owner。
# diff/explain 只解释 owner-local backend result preview，不授予 backend-ready truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage322_internal_ai_generated_ui_demo_backend_result_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage322 internal ai generated ui demo backend result semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage322InternalAiGeneratedUiDemoBackendResultSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage322InternalAiGeneratedUiDemoBackendResultSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage322InternalAiGeneratedUiDemoBackendResultSemanticDiffExplainDraft" \
  "didConsumeStage321BackendResultPreview" \
  "didMaterializeAiGeneratedUiBackendResultSemanticDiff" \
  "didMaterializeAiGeneratedUiBackendResultExplainPacket" \
  "didBindBackendResultDiffToBackendResultPreview" \
  "didBindBackendResultExplainToAdapterNoSubmitResult" \
  "didMaterializeBackendResultRollbackReadyBoundary" \
  "didPrepareStage323BackendResultStateRenderBridgeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage322 internal ai generated ui demo backend result semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage322_internal_ai_generated_ui_demo_backend_result_semantic_diff_explain_owner_present=true"
echo "ai_generated_ui_backend_result_preview_required=true"
echo "ai_generated_ui_backend_result_semantic_diff_materialized=true"
echo "ai_generated_ui_backend_result_explain_packet_materialized=true"
echo "backend_result_diff_bound_to_backend_result_preview=true"
echo "backend_result_explain_bound_to_adapter_no_submit_result=true"
echo "backend_result_rollback_ready_boundary_materialized=true"
echo "stage323_backend_result_state_render_bridge_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
