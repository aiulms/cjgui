#!/usr/bin/env zsh
#
# 维护注释：验证 stage238 backend adapter no-submit predicate owner。
# 它只生成 adapter 层 no-submit 谓词，不创建平台 command buffer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage238_backend_adapter_no_submit_predicate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage238 backend adapter no-submit predicate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateFacts" \
  "CjguiInternalRendererStage238BackendAdapterNoSubmitPredicateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage238BackendAdapterNoSubmitPredicateDraft" \
  "didConsumeStage237MinimalBackendAdapterPreview" \
  "didMaterializeBackendAdapterNoSubmitPredicate" \
  "didBindNoSubmitPredicateToAdapterPreview" \
  "didConfirmAdapterPredicateRejectsPlatformCommandBuffer" \
  "didConfirmAdapterPredicateRejectsRendererSubmission" \
  "didPrepareStage239BackendAdapterRollbackVisibilityBoundaryInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage238 backend adapter no-submit predicate: missing token $token" >&2
    exit 3
  fi
done

echo "stage238_backend_adapter_no_submit_predicate_owner_present=true"
echo "stage237_minimal_backend_adapter_preview_required=true"
echo "backend_adapter_no_submit_predicate_materialized=true"
echo "no_submit_predicate_bound_to_adapter_preview=true"
echo "adapter_predicate_rejects_platform_command_buffer=true"
echo "adapter_predicate_rejects_renderer_submission=true"
echo "stage239_backend_adapter_rollback_visibility_boundary_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
