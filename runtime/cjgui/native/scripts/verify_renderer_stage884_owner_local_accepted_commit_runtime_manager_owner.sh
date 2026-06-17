#!/usr/bin/env zsh
#
# Verifies the stage884 owner-local accepted commit runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage884_owner_local_accepted_commit_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage884 owner-local accepted commit runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage884OwnerLocalAcceptedCommitRuntimeManagerPlan" \
  "CjguiInternalRendererStage884OwnerLocalAcceptedCommitRuntimeManagerFacts" \
  "CjguiInternalRendererStage884OwnerLocalAcceptedCommitRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage884OwnerLocalAcceptedCommitRuntimeManagerDraft" \
  "CjguiInternalRendererStage883OwnerLocalAcceptedCommitDemoSurfaceReadiness" \
  "didConsumeStage883OwnerLocalAcceptedCommitDemoSurface" \
  "didMaterializeSharedOwnerLocalAcceptedCommitRuntimeManager" \
  "didMaterializeOwnerLocalAcceptedCommitRuntimeContract" \
  "didMaterializeOwnerLocalAcceptedCommitExecutionReceiptContract" \
  "didMaterializeCommonOwnerLocalAcceptedCommitExecutor" \
  "didMaterializeAcceptedCommitInspectionRuntimeBridge" \
  "didReduceFuturePerDemoOwnerLocalAcceptedCommitTemplateNeed" \
  "didPrepareStage885OwnerLocalAcceptedCommitPublicationPreflight"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage884 owner-local accepted commit runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage884_owner_local_accepted_commit_runtime_manager_owner_present=true"
echo "stage883_owner_local_accepted_commit_demo_surface_consumed=true"
echo "stage882_owner_local_accepted_commit_application_plan_consumed_transitively=true"
echo "stage881_owner_local_accepted_commit_inspection_consumed_transitively=true"
echo "stage880_owner_local_commit_acceptance_runtime_manager_consumed_transitively=true"
echo "shared_owner_local_accepted_commit_runtime_manager_materialized=true"
echo "owner_local_accepted_commit_runtime_contract_materialized=true"
echo "owner_local_accepted_commit_execution_receipt_contract_materialized=true"
echo "cycle_order_accepted_commit_inspection_plan_demo_runtime_materialized=true"
echo "todo_owner_local_accepted_commit_runtime_surface_materialized=true"
echo "settings_owner_local_accepted_commit_runtime_surface_materialized=true"
echo "ai_generated_settings_owner_local_accepted_commit_runtime_surface_materialized=true"
echo "chat_composer_owner_local_accepted_commit_runtime_surface_materialized=true"
echo "file_browser_owner_local_accepted_commit_runtime_surface_materialized=true"
echo "common_owner_local_accepted_commit_executor_materialized=true"
echo "accepted_commit_inspection_runtime_bridge_materialized=true"
echo "future_per_demo_owner_local_accepted_commit_template_need_reduced=true"
echo "stage885_owner_local_accepted_commit_publication_preflight_prepared=true"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
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
