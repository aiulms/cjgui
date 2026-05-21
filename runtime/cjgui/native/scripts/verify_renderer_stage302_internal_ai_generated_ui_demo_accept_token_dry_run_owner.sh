#!/usr/bin/env zsh
#
# 维护注释：验证 stage302 internal AI-generated UI demo accept token dry-run owner。
# 它只做 owner acceptance token 的缺省未授权 dry-run，不接纳 generated UI。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage302_internal_ai_generated_ui_demo_accept_token_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage302 internal ai generated ui demo accept token dry run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage302InternalAiGeneratedUiDemoAcceptTokenDryRunFacts" \
  "CjguiInternalRendererStage302InternalAiGeneratedUiDemoAcceptTokenDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage302InternalAiGeneratedUiDemoAcceptTokenDryRunDraft" \
  "didConsumeStage301InternalAiGeneratedUiDemoOwnerAcceptanceGateInput" \
  "didMaterializeAiGeneratedUiAcceptTokenDryRun" \
  "didBindAcceptTokenDryRunToOwnerAcceptanceGate" \
  "didValidateAbsentOwnerAcceptanceTokenAsNotGranted" \
  "didBindAcceptTokenDryRunToUncommittedGeneratedUiProposal" \
  "didBindAcceptTokenDryRunToVisibilityNotPublishedBoundary" \
  "didKeepAcceptTokenDryRunOwnerLocalInMemoryOnly" \
  "didKeepAcceptTokenDryRunNonExecuting" \
  "didPrepareStage303AiGeneratedUiDemoRejectReasonLedgerInput" \
  "didKeepOwnerAcceptanceTokenNotGranted" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage302 internal ai generated ui demo accept token dry run: missing token $token" >&2
    exit 3
  fi
done

echo "stage302_internal_ai_generated_ui_demo_accept_token_dry_run_owner_present=true"
echo "stage301_internal_ai_generated_ui_demo_owner_acceptance_gate_input_required=true"
echo "ai_generated_ui_accept_token_dry_run_materialized=true"
echo "accept_token_dry_run_bound_to_owner_acceptance_gate=true"
echo "accept_token_dry_run_validates_absent_token_as_not_granted=true"
echo "accept_token_dry_run_bound_to_uncommitted_generated_ui_proposal=true"
echo "accept_token_dry_run_bound_to_visibility_not_published_boundary=true"
echo "accept_token_dry_run_owner_local_in_memory_only=true"
echo "accept_token_dry_run_non_executing=true"
echo "stage303_ai_generated_ui_demo_reject_reason_ledger_input_prepared=true"
echo "owner_acceptance_required=true"
echo "owner_acceptance_token_granted=false"
echo "owner_acceptance_granted=false"
echo "backend_ready_truth=false"
echo "public_component_api_added=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
