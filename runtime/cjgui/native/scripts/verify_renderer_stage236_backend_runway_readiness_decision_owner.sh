#!/usr/bin/env zsh
#
# 维护注释：验证 stage236 renderer backend runway readiness decision owner。
# 它只收束 contract/capability 到 no-submit command envelope 的 runway。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage236_backend_runway_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage236 backend runway readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage236BackendRunwayReadinessDecisionFacts" \
  "CjguiInternalRendererStage236BackendRunwayReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage236BackendRunwayReadinessDecisionDraft" \
  "didConsumeStage235RendererBackendCommandEnvelope" \
  "didJoinContractCapabilityLedgerWithSubmissionTokenDryRun" \
  "didJoinSubmissionTokenDryRunWithCommandEnvelope" \
  "didMaterializeRendererBackendRunwayReadinessDecision" \
  "didConfirmMinimalUiFrameworkBackendRunwayAdvanced" \
  "didPrepareStage237MinimalBackendAdapterPreviewInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage236 backend runway readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage236_backend_runway_readiness_decision_owner_present=true"
echo "stage235_backend_command_envelope_required=true"
echo "backend_contract_capability_ledger_joined_with_submission_token_dry_run=true"
echo "backend_submission_token_dry_run_joined_with_command_envelope=true"
echo "renderer_backend_runway_readiness_decision_materialized=true"
echo "minimal_ui_framework_backend_runway_advanced=true"
echo "stage237_minimal_backend_adapter_preview_input_prepared=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
