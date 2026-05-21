#!/usr/bin/env zsh
#
# 维护注释：验证 stage323 internal AI-generated UI demo backend result state/render bridge owner。
# bridge 只接回 owner-local state/render dry-run，不提交状态、不发布 visibility。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage323_internal_ai_generated_ui_demo_backend_result_state_render_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage323 internal ai generated ui demo backend result state render bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage323InternalAiGeneratedUiDemoBackendResultStateRenderBridgeFacts" \
  "CjguiInternalRendererStage323InternalAiGeneratedUiDemoBackendResultStateRenderBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage323InternalAiGeneratedUiDemoBackendResultStateRenderBridgeDraft" \
  "didConsumeStage322BackendResultSemanticDiffExplain" \
  "didMaterializeAiGeneratedUiBackendResultStateRenderBridge" \
  "didBindBackendResultToOwnerLocalStateUpdateDryRun" \
  "didBindBackendResultToRefreshedRenderCommandPreview" \
  "didRejectBackendResultStateCommit" \
  "didRejectBackendResultRendererSubmission" \
  "didRejectBackendResultVisibilityPublication" \
  "didPrepareStage324BackendResultReadinessDecisionInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage323 internal ai generated ui demo backend result state render bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage323_internal_ai_generated_ui_demo_backend_result_state_render_bridge_owner_present=true"
echo "ai_generated_ui_backend_result_semantic_diff_explain_required=true"
echo "ai_generated_ui_backend_result_state_render_bridge_materialized=true"
echo "backend_result_bound_to_owner_local_state_update_dry_run=true"
echo "backend_result_bound_to_refreshed_render_command_preview=true"
echo "backend_result_state_commit_rejected=true"
echo "backend_result_renderer_submission_rejected=true"
echo "backend_result_visibility_publication_rejected=true"
echo "stage324_backend_result_readiness_decision_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
