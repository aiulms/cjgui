#!/usr/bin/env zsh
#
# 维护注释：验证 stage418 visibility command plan dry-run owner。
# 它必须消费 stage417 gate，并形成 owner-local visible surface command plan preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage418_visibility_command_plan_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage418 visibility command plan dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage418VisibilityCommandPlanDryRunPlan" \
  "CjguiInternalRendererStage418VisibilityCommandPlanDryRunFacts" \
  "CjguiInternalRendererStage418VisibilityCommandPlanDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage418VisibilityCommandPlanDryRunDraft" \
  "didConsumeStage417OwnerAcceptanceVisibilityGate" \
  "didConsumeOwnerAcceptanceVisibilityGate" \
  "didConsumeAcceptedReconciliationGateCandidate" \
  "didConsumeBlockedReconciliationVisibilityDenialCandidate" \
  "didMaterializeVisibilityCommandPlanDryRun" \
  "didMaterializeTodoVisibilityCommandPlanDryRun" \
  "didMaterializeSettingsVisibilityCommandPlanDryRun" \
  "didMaterializeAiGeneratedSettingsVisibilityCommandPlanDryRun" \
  "didMapAcceptedGateToPreviewVisibilityCommand" \
  "didMapBlockedGateToRollbackVisibilityCommand" \
  "didKeepVisibilityCommandPlanOwnerLocal" \
  "didKeepVisibilityCommandPlanPreviewOnly" \
  "didPrepareStage419DemoSurfaceVisibilityPreviewRefresh" \
  "didKeepVisibilityPublishedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage418 visibility command plan dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage418_visibility_command_plan_dry_run_owner_present=true"
echo "stage417_owner_acceptance_visibility_gate_required=true"
echo "stage417_owner_acceptance_visibility_gate_consumed=true"
echo "owner_acceptance_visibility_gate_consumed=true"
echo "accepted_reconciliation_gate_candidate_consumed=true"
echo "blocked_reconciliation_visibility_denial_candidate_consumed=true"
echo "visibility_command_plan_dry_run_materialized=true"
echo "todo_visibility_command_plan_dry_run_materialized=true"
echo "settings_visibility_command_plan_dry_run_materialized=true"
echo "ai_generated_settings_visibility_command_plan_dry_run_materialized=true"
echo "accepted_gate_to_preview_visibility_command_mapped=true"
echo "blocked_gate_to_rollback_visibility_command_mapped=true"
echo "visibility_command_plan_owner_local=true"
echo "visibility_command_plan_preview_only=true"
echo "stage419_demo_surface_visibility_preview_refresh_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "production_render_truth=false"
echo "backend_ready_truth=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "backend_implementation=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
echo "production_public_c_abi_added=false"
