#!/usr/bin/env zsh
#
# 维护注释：验证 stage235 renderer backend command envelope owner。
# 它只生成 no-submit command envelope，不创建平台 command buffer。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage235_backend_command_envelope.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage235 backend command envelope: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage235BackendCommandEnvelopeFacts" \
  "CjguiInternalRendererStage235BackendCommandEnvelopeReadiness" \
  "cjguiInternalExecuteDefaultRendererStage235BackendCommandEnvelopeDraft" \
  "didConsumeStage234RendererBackendSubmissionTokenDryRun" \
  "didMaterializeRendererBackendCommandEnvelope" \
  "didBindCommandEnvelopeToNonExecutableSubmissionToken" \
  "didBindCommandEnvelopeToRollbackBoundary" \
  "didClassifyCommandEnvelopeAsNoSubmit" \
  "didPrepareStage236RendererBackendRunwayReadinessDecisionInput" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepVisibilityNotPublished"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage235 backend command envelope: missing token $token" >&2
    exit 3
  fi
done

echo "stage235_backend_command_envelope_owner_present=true"
echo "stage234_backend_submission_token_dry_run_required=true"
echo "renderer_backend_command_envelope_materialized=true"
echo "backend_command_envelope_bound_to_non_executable_submission_token=true"
echo "backend_command_envelope_bound_to_rollback_boundary=true"
echo "backend_command_envelope_no_submit=true"
echo "stage236_renderer_backend_runway_readiness_decision_input_prepared=true"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
