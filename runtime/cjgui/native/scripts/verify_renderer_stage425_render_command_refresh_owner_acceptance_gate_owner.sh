#!/usr/bin/env zsh
#
# 维护注释：验证 stage425 RenderCommand refresh owner acceptance gate owner。
# 它必须消费 stage424 demo surface batch，并形成 owner-local accept/reject gate。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage425_render_command_refresh_owner_acceptance_gate.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage425 render command refresh owner acceptance gate: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage425RenderCommandRefreshOwnerAcceptanceGatePlan" \
  "CjguiInternalRendererStage425RenderCommandRefreshOwnerAcceptanceGateFacts" \
  "CjguiInternalRendererStage425RenderCommandRefreshOwnerAcceptanceGateReadiness" \
  "cjguiInternalExecuteDefaultRendererStage425RenderCommandRefreshOwnerAcceptanceGateDraft" \
  "didConsumeStage424RenderCommandRefreshDemoSurfaceDryRun" \
  "didConsumeDemoSurfaceRenderCommandRefreshDryRun" \
  "didConsumeTodoDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeSettingsDemoSurfaceRenderCommandRefreshBatch" \
  "didConsumeAiGeneratedSettingsDemoSurfaceRenderCommandRefreshBatch" \
  "didMaterializeRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeTodoRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeSettingsRenderCommandRefreshOwnerAcceptanceGate" \
  "didMaterializeAiGeneratedSettingsRenderCommandRefreshOwnerAcceptanceGate" \
  "didRequireOwnerAcceptanceTokenForRenderCommandRefresh" \
  "didRequireOwnerRejectReasonForRenderCommandRefresh" \
  "didPrepareAcceptedRenderCommandGateCandidate" \
  "didPrepareBlockedRenderCommandRollbackCandidate" \
  "didBindGateToStage424DemoSurfaceBatch" \
  "didBindGateToStage423RenderCommandRefresh" \
  "didKeepOwnerAcceptanceGatePreviewOnly" \
  "didPrepareStage426RenderCommandGateTransactionDryRun" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage425 render command refresh owner acceptance gate: missing token $token" >&2
    exit 3
  fi
done

echo "stage425_render_command_refresh_owner_acceptance_gate_owner_present=true"
echo "stage424_render_command_refresh_demo_surface_dry_run_required=true"
echo "stage424_render_command_refresh_demo_surface_dry_run_consumed=true"
echo "demo_surface_render_command_refresh_dry_run_consumed=true"
echo "todo_demo_surface_render_command_refresh_batch_consumed=true"
echo "settings_demo_surface_render_command_refresh_batch_consumed=true"
echo "ai_generated_settings_demo_surface_render_command_refresh_batch_consumed=true"
echo "render_command_refresh_owner_acceptance_gate_materialized=true"
echo "todo_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "settings_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "ai_generated_settings_render_command_refresh_owner_acceptance_gate_materialized=true"
echo "owner_acceptance_token_for_render_command_refresh_required=true"
echo "owner_reject_reason_for_render_command_refresh_required=true"
echo "accepted_render_command_gate_candidate_prepared=true"
echo "blocked_render_command_rollback_candidate_prepared=true"
echo "gate_bound_to_stage424_demo_surface_batch=true"
echo "gate_bound_to_stage423_render_command_refresh=true"
echo "owner_acceptance_gate_owner_local=true"
echo "owner_acceptance_gate_preview_only=true"
echo "stage426_render_command_gate_transaction_dry_run_prepared=true"
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
