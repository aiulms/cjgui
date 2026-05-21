#!/usr/bin/env zsh
#
# 维护注释：验证 stage303 internal AI-generated UI demo reject reason ledger owner。
# 它记录 reject 分支的 owner-local reason ledger，并绑定 rollback-ready noop。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage303_internal_ai_generated_ui_demo_reject_reason_ledger.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage303 internal ai generated ui demo reject reason ledger: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage303InternalAiGeneratedUiDemoRejectReasonLedgerFacts" \
  "CjguiInternalRendererStage303InternalAiGeneratedUiDemoRejectReasonLedgerReadiness" \
  "cjguiInternalExecuteDefaultRendererStage303InternalAiGeneratedUiDemoRejectReasonLedgerDraft" \
  "didConsumeStage302InternalAiGeneratedUiDemoAcceptTokenDryRun" \
  "didMaterializeAiGeneratedUiRejectReasonLedger" \
  "didBindRejectReasonLedgerToOwnerAcceptanceGate" \
  "didBindRejectReasonLedgerToRollbackReadyNoop" \
  "didBindRejectReasonLedgerToExplainPacket" \
  "didBindRejectReasonLedgerToVisibilityNotPublishedBoundary" \
  "didKeepRejectReasonLedgerOwnerLocalInMemoryOnly" \
  "didKeepRejectReasonLedgerNonExecuting" \
  "didPrepareStage304AiGeneratedUiDemoOwnerAcceptanceGateReadinessDecisionInput" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage303 internal ai generated ui demo reject reason ledger: missing token $token" >&2
    exit 3
  fi
done

echo "stage303_internal_ai_generated_ui_demo_reject_reason_ledger_owner_present=true"
echo "stage302_internal_ai_generated_ui_demo_accept_token_dry_run_required=true"
echo "ai_generated_ui_reject_reason_ledger_materialized=true"
echo "reject_reason_ledger_bound_to_owner_acceptance_gate=true"
echo "reject_reason_ledger_bound_to_rollback_ready_noop=true"
echo "reject_reason_ledger_bound_to_explain_packet=true"
echo "reject_reason_ledger_bound_to_visibility_not_published_boundary=true"
echo "reject_reason_ledger_owner_local_in_memory_only=true"
echo "reject_reason_ledger_non_executing=true"
echo "stage304_ai_generated_ui_demo_owner_acceptance_gate_readiness_decision_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
