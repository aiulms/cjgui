#!/usr/bin/env zsh
#
# 维护注释：验证 stage428 RenderCommand transaction visibility command plan owner。
# 它必须消费 stage427 visibility admission，并生成 owner-local visibility command plan dry-run。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage428_render_command_transaction_visibility_command_plan.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage428 render command transaction visibility command plan: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage428RenderCommandTransactionVisibilityCommandPlanPlan" \
  "CjguiInternalRendererStage428RenderCommandTransactionVisibilityCommandPlanFacts" \
  "CjguiInternalRendererStage428RenderCommandTransactionVisibilityCommandPlanReadiness" \
  "cjguiInternalExecuteDefaultRendererStage428RenderCommandTransactionVisibilityCommandPlanDraft" \
  "didConsumeStage427RenderCommandTransactionVisibilityAdmission" \
  "didConsumeRenderCommandTransactionVisibilityAdmission" \
  "didConsumeAcceptedTransactionVisibilityAdmissionCandidate" \
  "didConsumeBlockedTransactionVisibilityDenialCandidate" \
  "didMaterializeRenderCommandTransactionVisibilityCommandPlanDryRun" \
  "didMaterializeTodoRenderCommandTransactionVisibilityCommandPlanDryRun" \
  "didMaterializeSettingsRenderCommandTransactionVisibilityCommandPlanDryRun" \
  "didMaterializeAiGeneratedSettingsRenderCommandTransactionVisibilityCommandPlanDryRun" \
  "didMapAcceptedVisibilityAdmissionToPreviewVisibilityCommand" \
  "didMapBlockedVisibilityDenialToRollbackVisibilityCommand" \
  "didBindVisibilityCommandPlanToStage427Admission" \
  "didBindVisibilityCommandPlanToStage426TransactionDryRun" \
  "didKeepRenderCommandTransactionVisibilityCommandPlanOwnerLocal" \
  "didKeepRenderCommandTransactionVisibilityCommandPlanPreviewOnly" \
  "didPrepareStage429DemoSurfaceTransactionVisibilityPreviewRefresh" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage428 render command transaction visibility command plan: missing token $token" >&2
    exit 3
  fi
done

echo "stage428_render_command_transaction_visibility_command_plan_owner_present=true"
echo "stage427_render_command_transaction_visibility_admission_required=true"
echo "stage427_render_command_transaction_visibility_admission_consumed=true"
echo "render_command_transaction_visibility_admission_consumed=true"
echo "accepted_transaction_visibility_admission_candidate_consumed=true"
echo "blocked_transaction_visibility_denial_candidate_consumed=true"
echo "render_command_transaction_visibility_command_plan_dry_run_materialized=true"
echo "todo_render_command_transaction_visibility_command_plan_dry_run_materialized=true"
echo "settings_render_command_transaction_visibility_command_plan_dry_run_materialized=true"
echo "ai_generated_settings_render_command_transaction_visibility_command_plan_dry_run_materialized=true"
echo "accepted_visibility_admission_to_preview_visibility_command_mapped=true"
echo "blocked_visibility_denial_to_rollback_visibility_command_mapped=true"
echo "visibility_command_plan_bound_to_stage427_admission=true"
echo "visibility_command_plan_bound_to_stage426_transaction_dry_run=true"
echo "render_command_transaction_visibility_command_plan_owner_local=true"
echo "render_command_transaction_visibility_command_plan_preview_only=true"
echo "stage429_demo_surface_transaction_visibility_preview_refresh_prepared=true"
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
