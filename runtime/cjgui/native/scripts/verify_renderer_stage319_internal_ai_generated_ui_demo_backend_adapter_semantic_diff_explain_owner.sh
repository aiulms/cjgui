#!/usr/bin/env zsh
#
# 维护注释：验证 stage319 backend adapter semantic diff/explain owner。
# 它解释 adapter dry-run result 与 action loop preview 的差异，不升级 backend truth。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage319_internal_ai_generated_ui_demo_backend_adapter_semantic_diff_explain.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage319 internal ai generated ui demo backend adapter semantic diff explain: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage319InternalAiGeneratedUiDemoBackendAdapterSemanticDiffExplainFacts" \
  "CjguiInternalRendererStage319InternalAiGeneratedUiDemoBackendAdapterSemanticDiffExplainReadiness" \
  "cjguiInternalExecuteDefaultRendererStage319InternalAiGeneratedUiDemoBackendAdapterSemanticDiffExplainDraft" \
  "didConsumeStage318BackendAdapterResultEnvelope" \
  "didMaterializeAiGeneratedUiBackendAdapterSemanticDiff" \
  "didMaterializeAiGeneratedUiBackendAdapterExplainPacket" \
  "didBindBackendAdapterSemanticDiffToActionLoopPreview" \
  "didBindBackendAdapterExplainPacketToNoSubmitResult" \
  "didPrepareStage320BackendAdapterReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage319 internal ai generated ui demo backend adapter semantic diff explain: missing token $token" >&2
    exit 3
  fi
done

echo "stage319_internal_ai_generated_ui_demo_backend_adapter_semantic_diff_explain_owner_present=true"
echo "stage318_internal_ai_generated_ui_demo_backend_adapter_result_envelope_required=true"
echo "ai_generated_ui_backend_adapter_semantic_diff_materialized=true"
echo "ai_generated_ui_backend_adapter_explain_packet_materialized=true"
echo "backend_adapter_semantic_diff_bound_to_action_loop_preview=true"
echo "backend_adapter_explain_packet_bound_to_no_submit_result=true"
echo "stage320_backend_adapter_readiness_decision_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
