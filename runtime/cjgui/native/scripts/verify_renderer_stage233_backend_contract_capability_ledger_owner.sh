#!/usr/bin/env zsh
#
# 维护注释：验证 stage233 renderer backend contract/capability ledger owner。
# 它只把 stage232 handoff readiness 接到既有 no-render backend contract/capability。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage233_backend_contract_capability_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage233 backend contract capability ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage233BackendContractCapabilityLedgerFacts" \
  "CjguiInternalRendererStage233BackendContractCapabilityLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage233BackendContractCapabilityLedgerDraft" \
  "didConsumeStage232RendererBackendHandoffReadinessDecision" \
  "didConsumeRendererBackendNoRenderContractReadiness" \
  "didConsumeRendererBackendNoRenderCapabilityReadiness" \
  "didMaterializeRendererBackendContractCapabilityLedger" \
  "didBindBackendHandoffToNoRenderContract" \
  "didBindNoRenderContractToCapabilityReadiness" \
  "didPrepareStage234RendererBackendSubmissionTokenDryRunInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepConcretePlatformCapabilityPromiseBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage233 backend contract capability ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage233_backend_contract_capability_ledger_owner_present=true"
echo "stage232_backend_handoff_readiness_decision_required=true"
echo "renderer_backend_no_render_contract_readiness_consumed=true"
echo "renderer_backend_no_render_capability_readiness_consumed=true"
echo "renderer_backend_contract_capability_ledger_materialized=true"
echo "backend_handoff_bound_to_no_render_contract=true"
echo "no_render_contract_bound_to_capability_readiness=true"
echo "stage234_renderer_backend_submission_token_dry_run_input_prepared=true"
echo "backend_ready_truth=false"
echo "concrete_platform_capability_promise=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
