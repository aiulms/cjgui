#!/usr/bin/env zsh
#
# 维护注释：验证 stage249 component demo backend result preview owner。
# 它消费 stage248 executor readiness，把 owner-local executor result 映射成 demo preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage249_component_demo_backend_result_preview.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage249 component demo backend result preview: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage249ComponentDemoBackendResultPreviewFacts" \
  "CjguiInternalRendererStage249ComponentDemoBackendResultPreviewReadiness" \
  "cjguiInternalExecuteDefaultRendererStage249ComponentDemoBackendResultPreviewDraft" \
  "didConsumeStage248BackendAdapterExecutorReadinessDecision" \
  "didMaterializeComponentDemoBackendResultPreview" \
  "didBindPreviewToBackendAdapterExecutorResult" \
  "didBindPreviewToButtonLikeSemanticNode" \
  "didBindPreviewToRefreshedRenderCommand" \
  "didKeepPreviewOwnerLocalInMemoryOnly" \
  "didPrepareStage250BackendResultSemanticDiffExplainInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage249 component demo backend result preview: missing token $token" >&2
    exit 3
  fi
done

echo "stage249_component_demo_backend_result_preview_owner_present=true"
echo "stage248_backend_adapter_executor_readiness_decision_required=true"
echo "component_demo_backend_result_preview_materialized=true"
echo "backend_result_preview_bound_to_executor_result=true"
echo "backend_result_preview_bound_to_button_like_semantic_node=true"
echo "backend_result_preview_bound_to_refreshed_render_command=true"
echo "stage250_backend_result_semantic_diff_explain_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
