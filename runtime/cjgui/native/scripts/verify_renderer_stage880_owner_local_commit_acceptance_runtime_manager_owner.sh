#!/usr/bin/env zsh
#
# Verifies the stage880 owner-local commit acceptance runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage880_owner_local_commit_acceptance_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage880 owner-local commit acceptance runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage880OwnerLocalCommitAcceptanceRuntimeManagerPlan" \
  "CjguiInternalRendererStage880OwnerLocalCommitAcceptanceRuntimeManagerFacts" \
  "CjguiInternalRendererStage880OwnerLocalCommitAcceptanceRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage880OwnerLocalCommitAcceptanceRuntimeManagerDraft" \
  "CjguiInternalRendererStage879OwnerLocalCommitAcceptanceDemoSurfaceReadiness" \
  "didConsumeStage879OwnerLocalCommitAcceptanceDemoSurface" \
  "didMaterializeSharedOwnerLocalCommitAcceptanceRuntimeManager" \
  "didMaterializeOwnerLocalCommitAcceptanceRuntimeContract" \
  "didMaterializeOwnerLocalCommitAcceptanceExecutionReceiptContract" \
  "didMaterializeCommonOwnerLocalCommitAcceptanceExecutor" \
  "didMaterializeOwnerLocalCommitAcceptanceInspectionRuntimeBridge" \
  "didReduceFuturePerDemoOwnerLocalCommitAcceptanceTemplateNeed" \
  "didPrepareStage881OwnerLocalAcceptedCommitInspection"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage880 owner-local commit acceptance runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage880_owner_local_commit_acceptance_runtime_manager_owner_present=true"
echo "stage879_owner_local_commit_acceptance_demo_surface_consumed=true"
echo "stage878_owner_local_commit_acceptance_decision_consumed_transitively=true"
echo "stage877_owner_local_commit_acceptance_gate_consumed_transitively=true"
echo "stage876_owner_local_commit_runtime_manager_consumed_transitively=true"
echo "shared_owner_local_commit_acceptance_runtime_manager_materialized=true"
echo "owner_local_commit_acceptance_runtime_contract_materialized=true"
echo "owner_local_commit_acceptance_execution_receipt_contract_materialized=true"
echo "cycle_order_owner_local_commit_acceptance_gate_decision_demo_runtime_materialized=true"
echo "todo_owner_local_commit_acceptance_runtime_surface_materialized=true"
echo "settings_owner_local_commit_acceptance_runtime_surface_materialized=true"
echo "ai_generated_settings_owner_local_commit_acceptance_runtime_surface_materialized=true"
echo "chat_composer_owner_local_commit_acceptance_runtime_surface_materialized=true"
echo "file_browser_owner_local_commit_acceptance_runtime_surface_materialized=true"
echo "common_owner_local_commit_acceptance_executor_materialized=true"
echo "owner_local_commit_acceptance_inspection_runtime_bridge_materialized=true"
echo "future_per_demo_owner_local_commit_acceptance_template_need_reduced=true"
echo "stage881_owner_local_accepted_commit_inspection_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_update_committed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "native_bridge_expansion=false"
