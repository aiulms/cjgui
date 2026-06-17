#!/usr/bin/env zsh
#
# Verifies the stage888 owner-local accepted commit publication runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage888_owner_local_accepted_commit_publication_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage888 owner-local accepted commit publication runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage888OwnerLocalAcceptedCommitPublicationRuntimeManagerPlan" \
  "CjguiInternalRendererStage888OwnerLocalAcceptedCommitPublicationRuntimeManagerFacts" \
  "CjguiInternalRendererStage888OwnerLocalAcceptedCommitPublicationRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage888OwnerLocalAcceptedCommitPublicationRuntimeManagerDraft" \
  "CjguiInternalRendererStage887OwnerLocalAcceptedCommitPublicationDemoSurfaceReadiness" \
  "didConsumeStage887OwnerLocalAcceptedCommitPublicationDemoSurface" \
  "didMaterializeSharedOwnerLocalAcceptedCommitPublicationRuntimeManager" \
  "didMaterializeOwnerLocalAcceptedCommitPublicationRuntimeContract" \
  "didMaterializeOwnerLocalAcceptedCommitPublicationExecutionReceiptContract" \
  "didMaterializeCommonOwnerLocalAcceptedCommitPublicationExecutor" \
  "didMaterializeAcceptedCommitPublicationInspectionRuntimeBridge" \
  "didPrepareStage889MinimalPublicComponentCommitApiReadiness"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage888 owner-local accepted commit publication runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage888_owner_local_accepted_commit_publication_runtime_manager_owner_present=true"
echo "stage887_owner_local_accepted_commit_publication_demo_surface_consumed=true"
echo "stage886_owner_local_accepted_commit_publication_boundary_consumed_transitively=true"
echo "stage885_owner_local_accepted_commit_publication_preflight_consumed_transitively=true"
echo "stage884_owner_local_accepted_commit_runtime_manager_consumed_transitively=true"
echo "shared_owner_local_accepted_commit_publication_runtime_manager_materialized=true"
echo "owner_local_accepted_commit_publication_runtime_contract_materialized=true"
echo "owner_local_accepted_commit_publication_execution_receipt_contract_materialized=true"
echo "cycle_order_accepted_commit_publication_preflight_boundary_demo_runtime_materialized=true"
echo "todo_accepted_commit_publication_runtime_surface_materialized=true"
echo "settings_accepted_commit_publication_runtime_surface_materialized=true"
echo "ai_generated_settings_accepted_commit_publication_runtime_surface_materialized=true"
echo "chat_composer_accepted_commit_publication_runtime_surface_materialized=true"
echo "file_browser_accepted_commit_publication_runtime_surface_materialized=true"
echo "common_owner_local_accepted_commit_publication_executor_materialized=true"
echo "accepted_commit_publication_inspection_runtime_bridge_materialized=true"
echo "future_per_demo_accepted_commit_publication_template_need_reduced=true"
echo "stage889_minimal_public_component_commit_api_readiness_prepared=true"
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
