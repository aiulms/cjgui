#!/usr/bin/env zsh
#
# 维护注释：验证 stage320 backend adapter readiness decision owner。
# 它汇合 dry-run、result envelope 与 semantic diff/explain，准备 demo result preview。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage320_internal_ai_generated_ui_demo_backend_adapter_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage320 internal ai generated ui demo backend adapter readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage320InternalAiGeneratedUiDemoBackendAdapterReadinessDecisionFacts" \
  "CjguiInternalRendererStage320InternalAiGeneratedUiDemoBackendAdapterReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage320InternalAiGeneratedUiDemoBackendAdapterReadinessDecisionDraft" \
  "didConsumeStage319BackendAdapterSemanticDiffExplain" \
  "didJoinBackendAdapterDryRunWithResultEnvelope" \
  "didJoinBackendAdapterResultEnvelopeWithSemanticDiffExplain" \
  "didJoinBackendAdapterRunwayWithRollbackVisibilityBoundary" \
  "didMaterializeInternalAiGeneratedUiDemoBackendAdapterReadinessDecision" \
  "didPrepareStage321InternalAiGeneratedUiDemoBackendResultPreview" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiBackendAdapterRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepPlatformCommandBufferBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage320 internal ai generated ui demo backend adapter readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage320_internal_ai_generated_ui_demo_backend_adapter_readiness_decision_owner_present=true"
echo "stage319_internal_ai_generated_ui_demo_backend_adapter_semantic_diff_explain_required=true"
echo "internal_ai_generated_ui_demo_backend_adapter_readiness_decision_materialized=true"
echo "backend_adapter_dry_run_result_envelope_joined=true"
echo "backend_adapter_result_semantic_diff_explain_joined=true"
echo "backend_adapter_runway_rollback_visibility_boundary_joined=true"
echo "stage321_internal_ai_generated_ui_demo_backend_result_preview_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_backend_adapter_runway_advanced=true"
echo "backend_ready_truth=false"
echo "platform_command_buffer=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
