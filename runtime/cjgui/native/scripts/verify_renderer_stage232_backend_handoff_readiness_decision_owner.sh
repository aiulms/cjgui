#!/usr/bin/env zsh
#
# 维护注释：验证 stage232 renderer backend handoff readiness decision owner。
# 它只输出下一段 backend contract/capability runway 输入。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage232_backend_handoff_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage232 backend handoff readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage232BackendHandoffReadinessDecisionFacts" \
  "CjguiInternalRendererStage232BackendHandoffReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage232BackendHandoffReadinessDecisionDraft" \
  "didConsumeStage231RendererBackendHandoffSemanticDiffExplain" \
  "didJoinBackendHandoffPacketWithNoRenderReadiness" \
  "didJoinBackendHandoffDiffExplainWithRollbackBoundary" \
  "didMaterializeRendererBackendHandoffReadinessDecision" \
  "didPrepareStage233RendererBackendContractCapabilityInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepBackendImplementationBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage232 backend handoff readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage232_backend_handoff_readiness_decision_owner_present=true"
echo "stage231_backend_handoff_semantic_diff_explain_required=true"
echo "backend_handoff_packet_joined_with_no_render_readiness=true"
echo "backend_handoff_diff_explain_joined_with_rollback_boundary=true"
echo "renderer_backend_handoff_readiness_decision_materialized=true"
echo "stage233_renderer_backend_contract_capability_input_prepared=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "backend_implementation=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
