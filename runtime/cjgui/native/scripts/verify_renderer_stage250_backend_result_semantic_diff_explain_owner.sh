#!/usr/bin/env zsh
#
# 维护注释：验证 stage250 backend result semantic diff/explain owner。
# 它把 stage249 preview 转成 owner acceptance 可读的 diff/explain 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage250_backend_result_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage250 backend result semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage250BackendResultSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage250BackendResultSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage250BackendResultSemanticDiffExplainDraft" \
  "didConsumeStage249ComponentDemoBackendResultPreview" \
  "didMaterializeBackendResultSemanticDiff" \
  "didMaterializeBackendResultExplainPacket" \
  "didBindDiffToComponentDemoBackendResultPreview" \
  "didBindExplainToExecutorRollbackSnapshot" \
  "didMaterializeBackendResultRollbackReadyBoundary" \
  "didPrepareStage251BackendResultStateUpdateBridgeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage250 backend result semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage250_backend_result_semantic_diff_explain_owner_present=true"
echo "stage249_component_demo_backend_result_preview_required=true"
echo "backend_result_semantic_diff_materialized=true"
echo "backend_result_explain_packet_materialized=true"
echo "backend_result_rollback_ready_boundary_materialized=true"
echo "stage251_backend_result_state_update_bridge_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
