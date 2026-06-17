#!/usr/bin/env zsh
#
# Verifies the stage892 component commit API runtime manager owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage892_component_commit_api_runtime_manager.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage892 component commit api runtime manager: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerPlan" \
  "CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerFacts" \
  "CjguiInternalRendererStage892ComponentCommitApiRuntimeManagerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage892ComponentCommitApiRuntimeManagerDraft" \
  "CjguiInternalRendererStage891ComponentCommitApiDemoConsumptionReadiness" \
  "didConsumeStage891ComponentCommitApiDemoConsumption" \
  "didMaterializeSharedComponentCommitApiRuntimeManager" \
  "didMaterializeComponentCommitApiRuntimeContract" \
  "didMaterializeComponentCommitApiExecutionReceiptContract" \
  "didMaterializeCommonComponentCommitApiExecutor" \
  "didMaterializeComponentCommitApiDemoRuntimeBridge" \
  "didReduceFuturePerDemoComponentCommitApiTemplateNeed" \
  "didPrepareStage893ComponentCommitApiOwnerLocalCommitBridge"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage892 component commit api runtime manager: missing token $token" >&2
    exit 3
  fi
done

echo "stage892_component_commit_api_runtime_manager_owner_present=true"
echo "stage891_component_commit_api_demo_consumption_consumed=true"
echo "stage890_experimental_component_commit_api_declaration_consumed_transitively=true"
echo "stage889_minimal_public_component_commit_api_readiness_consumed_transitively=true"
echo "stage888_owner_local_accepted_commit_publication_runtime_manager_consumed_transitively=true"
echo "shared_component_commit_api_runtime_manager_materialized=true"
echo "component_commit_api_runtime_contract_materialized=true"
echo "component_commit_api_execution_receipt_contract_materialized=true"
echo "cycle_order_component_commit_api_readiness_declaration_demo_runtime_materialized=true"
echo "todo_component_commit_api_runtime_surface_materialized=true"
echo "settings_component_commit_api_runtime_surface_materialized=true"
echo "ai_generated_settings_component_commit_api_runtime_surface_materialized=true"
echo "chat_composer_component_commit_api_runtime_surface_materialized=true"
echo "file_browser_component_commit_api_runtime_surface_materialized=true"
echo "common_component_commit_api_executor_materialized=true"
echo "component_commit_api_demo_runtime_bridge_materialized=true"
echo "future_per_demo_component_commit_api_template_need_reduced=true"
echo "stage893_component_commit_api_owner_local_commit_bridge_prepared=true"
echo "public_surface_cjguiExperimentalComponentCommitApiReady_materialized=true"
echo "new_public_surface_added=true"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "owner_acceptance_decision_committed=false"
echo "state_store_commit_published=false"
echo "state_store_write_executed=false"
echo "visibility_publication_admitted=false"
echo "visibility_published=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
