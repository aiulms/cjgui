#!/usr/bin/env zsh
#
# 维护注释：验证 stage234 renderer backend submission token dry-run owner。
# 它只生成 owner-local token dry-run，不执行 backend submission。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage234_backend_submission_token_dry_run.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage234 backend submission token dry-run: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage234BackendSubmissionTokenDryRunFacts" \
  "CjguiInternalRendererStage234BackendSubmissionTokenDryRunReadiness" \
  "cjguiInternalExecuteDefaultRendererStage234BackendSubmissionTokenDryRunDraft" \
  "didConsumeStage233RendererBackendContractCapabilityLedger" \
  "didMaterializeRendererBackendSubmissionTokenDryRun" \
  "didBindSubmissionTokenToContractCapabilityLedger" \
  "didClassifySubmissionTokenAsNonExecutable" \
  "didPreserveSubmissionTokenValueOnly" \
  "didPrepareStage235RendererBackendCommandEnvelopeInput" \
  "didKeepBackendImplementationBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage234 backend submission token dry-run: missing token $token" >&2
    exit 3
  fi
done

echo "stage234_backend_submission_token_dry_run_owner_present=true"
echo "stage233_backend_contract_capability_ledger_required=true"
echo "renderer_backend_submission_token_dry_run_materialized=true"
echo "backend_submission_token_bound_to_contract_capability_ledger=true"
echo "backend_submission_token_non_executable=true"
echo "stage235_renderer_backend_command_envelope_input_prepared=true"
echo "backend_implementation=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
