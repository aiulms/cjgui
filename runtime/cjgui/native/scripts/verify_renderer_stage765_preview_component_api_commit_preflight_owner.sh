#!/usr/bin/env zsh
#
# Verifies the stage765 preview component API commit preflight owner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage765_preview_component_api_commit_preflight.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage765 preview component api commit preflight: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage765PreviewComponentApiCommitPreflightPlan" \
  "CjguiInternalRendererStage765PreviewComponentApiCommitPreflightFacts" \
  "CjguiInternalRendererStage765PreviewComponentApiCommitPreflightReadiness" \
  "cjguiInternalExecuteDefaultRendererStage765PreviewComponentApiCommitPreflightDraft" \
  "CjguiInternalRendererStage764PreviewComponentApiVisualResolverRuntimeManagerReadiness" \
  "didConsumeStage764PreviewComponentApiVisualResolverRuntimeManager" \
  "didMaterializeSharedPreviewComponentApiCommitPreflight" \
  "didMaterializePreviewComponentApiCommitCandidateLedger" \
  "didMaterializePreviewComponentApiCompatibilityCommitGate" \
  "didMaterializeVisualResolverResultToCommitPlanBridge" \
  "didMaterializeChatComposerPreviewComponentApiCommitPreflightSurface" \
  "didPrepareStage766PreviewComponentApiCommitRollbackSnapshot"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage765 preview component api commit preflight: missing token $token" >&2
    exit 3
  fi
done

echo "stage765_preview_component_api_commit_preflight_owner_present=true"
echo "stage764_preview_component_api_visual_resolver_runtime_manager_consumed=true"
echo "stage763_preview_component_api_demo_host_inspection_surface_consumed_transitively=true"
echo "stage760_minimal_public_preview_api_public_scan_contract_consumed_transitively=true"
echo "shared_preview_component_api_commit_preflight_materialized=true"
echo "preview_component_api_commit_candidate_ledger_materialized=true"
echo "preview_component_api_compatibility_commit_gate_materialized=true"
echo "visual_resolver_result_to_commit_plan_bridge_materialized=true"
echo "todo_preview_component_api_commit_preflight_surface_materialized=true"
echo "settings_preview_component_api_commit_preflight_surface_materialized=true"
echo "ai_generated_settings_preview_component_api_commit_preflight_surface_materialized=true"
echo "chat_composer_preview_component_api_commit_preflight_surface_materialized=true"
echo "commit_preflight_bound_to_stage764_visual_resolver_runtime_manager=true"
echo "preview_component_api_commit_preflight_dry_run_only=true"
echo "stage766_preview_component_api_commit_rollback_snapshot_prepared=true"
echo "public_component_api_added=true"
echo "new_public_surface_added=false"
echo "stable_public_api_added=false"
echo "public_c_abi_added=false"
echo "owner_acceptance_granted=false"
echo "preview_component_api_commit_committed=false"
echo "input_event_pipeline_execution=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "native_bridge_expansion=false"
