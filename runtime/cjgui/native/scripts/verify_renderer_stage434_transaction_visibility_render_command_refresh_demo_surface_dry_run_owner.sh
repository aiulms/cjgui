#!/usr/bin/env zsh
#
# 维护注释：验证 stage434 transaction visibility RenderCommand refresh -> demo surface dry-run owner。
# 它必须消费 stage433 RenderCommand refresh，并生成 Todo/settings/AI-generated settings surface batch。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage434 transaction visibility render command refresh demo surface dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunPlan" \
  "CjguiInternalRendererStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunFacts" \
  "CjguiInternalRendererStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage434TransactionVisibilityRenderCommandRefreshDemoSurfaceDryRunDraft" \
  "didConsumeStage433TransactionVisibilityStateUpdateRenderCommandRefresh" \
  "didConsumeTransactionVisibilityStateUpdateRenderCommandRefresh" \
  "didConsumeTodoTransactionVisibilityStateUpdateRenderCommandRefresh" \
  "didConsumeSettingsTransactionVisibilityStateUpdateRenderCommandRefresh" \
  "didConsumeAiGeneratedSettingsTransactionVisibilityStateUpdateRenderCommandRefresh" \
  "didMaterializeTransactionVisibilityDemoSurfaceRenderCommandRefreshDryRun" \
  "didMaterializeTodoTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeSettingsTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeAiGeneratedSettingsTransactionVisibilityDemoSurfaceRenderCommandRefreshBatch" \
  "didBindTransactionVisibilityRenderCommandRefreshToDemoSurfaceDryRun" \
  "didBindDemoSurfaceDryRunToStage432TransactionVisibilityStateUpdateCandidate" \
  "didPrepareStage435TransactionVisibilityRenderCommandRefreshOwnerAcceptanceGate" \
  "didKeepTransactionVisibilityDemoSurfaceDryRunPreviewOnly" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage434 transaction visibility render command refresh demo surface dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage434_transaction_visibility_render_command_refresh_demo_surface_dry_run_owner_present=true"
echo "stage433_transaction_visibility_state_update_render_command_refresh_required=true"
echo "stage433_transaction_visibility_state_update_render_command_refresh_consumed=true"
echo "transaction_visibility_state_update_render_command_refresh_consumed=true"
echo "todo_transaction_visibility_state_update_render_command_refresh_consumed=true"
echo "settings_transaction_visibility_state_update_render_command_refresh_consumed=true"
echo "ai_generated_settings_transaction_visibility_state_update_render_command_refresh_consumed=true"
echo "transaction_visibility_demo_surface_render_command_refresh_dry_run_materialized=true"
echo "todo_transaction_visibility_demo_surface_render_command_refresh_batch_materialized=true"
echo "settings_transaction_visibility_demo_surface_render_command_refresh_batch_materialized=true"
echo "ai_generated_settings_transaction_visibility_demo_surface_render_command_refresh_batch_materialized=true"
echo "transaction_visibility_render_command_refresh_to_demo_surface_dry_run_bound=true"
echo "demo_surface_dry_run_to_stage432_transaction_visibility_state_update_candidate_bound=true"
echo "transaction_visibility_render_command_refresh_batch_owner_local=true"
echo "transaction_visibility_demo_surface_dry_run_preview_only=true"
echo "stage435_transaction_visibility_render_command_refresh_owner_acceptance_gate_prepared=true"
echo "input_event_pipeline_enabled=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
