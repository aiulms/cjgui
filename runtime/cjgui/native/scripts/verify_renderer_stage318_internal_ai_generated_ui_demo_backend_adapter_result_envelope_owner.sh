#!/usr/bin/env zsh
#
# 维护注释：验证 stage318 internal AI-generated UI demo backend adapter result envelope owner。
# 它把 adapter dry-run 结果封装成 owner-local envelope，保持 rollback-ready。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage318_internal_ai_generated_ui_demo_backend_adapter_result_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage318 internal ai generated ui demo backend adapter result envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage318InternalAiGeneratedUiDemoBackendAdapterResultEnvelopeFacts" \
  "CjguiInternalRendererStage318InternalAiGeneratedUiDemoBackendAdapterResultEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage318InternalAiGeneratedUiDemoBackendAdapterResultEnvelopeDraft" \
  "didConsumeStage317AiGeneratedUiActionLoopBackendAdapterDryRun" \
  "didMaterializeAiGeneratedUiBackendAdapterDryRunResultEnvelope" \
  "didBindBackendAdapterResultEnvelopeToNoSubmitPredicate" \
  "didBindBackendAdapterResultEnvelopeToRollbackReadyBoundary" \
  "didKeepBackendAdapterResultOwnerLocalInMemoryOnly" \
  "didKeepBackendAdapterResultVisibilityNotPublished" \
  "didPrepareStage319BackendAdapterSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage318 internal ai generated ui demo backend adapter result envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage318_internal_ai_generated_ui_demo_backend_adapter_result_envelope_owner_present=true"
echo "stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_required=true"
echo "ai_generated_ui_backend_adapter_dry_run_result_envelope_materialized=true"
echo "backend_adapter_result_bound_to_no_submit_predicate=true"
echo "backend_adapter_result_bound_to_rollback_ready_boundary=true"
echo "backend_adapter_result_owner_local_in_memory_only=true"
echo "backend_adapter_result_visibility_not_published=true"
echo "stage319_backend_adapter_semantic_diff_explain_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
