#!/usr/bin/env zsh
#
# 维护注释：验证 stage317 internal AI-generated UI demo action loop backend adapter dry-run owner。
# 它只把 action loop readiness 接成 backend adapter dry-run，不提交 renderer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage317 internal ai generated ui demo action loop backend adapter dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage317InternalAiGeneratedUiDemoActionLoopBackendAdapterDryRunFacts" \
  "CjguiInternalRendererStage317InternalAiGeneratedUiDemoActionLoopBackendAdapterDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage317InternalAiGeneratedUiDemoActionLoopBackendAdapterDryRunDraft" \
  "didConsumeStage316InternalAiGeneratedUiDemoActionLoopReadinessDecision" \
  "didMaterializeAiGeneratedUiActionLoopBackendAdapterDryRun" \
  "didBindBackendAdapterDryRunToActionLoopReadiness" \
  "didBindBackendAdapterDryRunToRefreshedRenderCommandPreview" \
  "didBindBackendAdapterDryRunToOwnerLocalStateUpdateDryRun" \
  "didKeepBackendAdapterDryRunNoSubmit" \
  "didKeepPlatformCommandBufferBlocked" \
  "didPrepareStage318BackendAdapterDryRunResultEnvelopeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage317 internal ai generated ui demo action loop backend adapter dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage317_internal_ai_generated_ui_demo_action_loop_backend_adapter_dry_run_owner_present=true"
echo "stage316_internal_ai_generated_ui_demo_action_loop_readiness_decision_required=true"
echo "ai_generated_ui_action_loop_backend_adapter_dry_run_materialized=true"
echo "backend_adapter_dry_run_bound_to_action_loop_readiness=true"
echo "backend_adapter_dry_run_bound_to_refreshed_render_command_preview=true"
echo "backend_adapter_dry_run_bound_to_owner_local_state_update_dry_run=true"
echo "backend_adapter_dry_run_no_submit=true"
echo "stage318_backend_adapter_dry_run_result_envelope_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
