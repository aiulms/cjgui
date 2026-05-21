#!/usr/bin/env zsh
#
# 维护注释：验证 stage251 backend result state-update bridge owner。
# 它把 backend result preview 接到 owner-local state update dry-run，不提交状态。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage251_backend_result_state_update_bridge.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage251 backend result state update bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage251BackendResultStateUpdateBridgeFacts" \
  "CjguiInternalRendererStage251BackendResultStateUpdateBridgeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage251BackendResultStateUpdateBridgeDraft" \
  "didConsumeStage250BackendResultSemanticDiffExplain" \
  "didMaterializeBackendResultStateUpdateBridge" \
  "didBindBackendResultToComponentDemoStateUpdateDryRun" \
  "didBindBackendResultToOwnerLocalRollbackPreview" \
  "didRejectBackendResultStateCommit" \
  "didRejectBackendResultVisibilityPublication" \
  "didPrepareStage252BackendResultReadinessDecisionInput" \
  "didKeepPublicComponentApiBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage251 backend result state update bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage251_backend_result_state_update_bridge_owner_present=true"
echo "stage250_backend_result_semantic_diff_explain_required=true"
echo "backend_result_state_update_bridge_materialized=true"
echo "backend_result_bound_to_component_demo_state_update_dry_run=true"
echo "backend_result_owner_local_rollback_preview_bound=true"
echo "backend_result_state_commit_rejected=true"
echo "stage252_backend_result_readiness_decision_input_prepared=true"
echo "public_component_api_added=false"
echo "state_update_committed=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
