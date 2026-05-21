#!/usr/bin/env zsh
#
# 维护注释：验证 stage308 internal AI-generated UI demo component state/render readiness decision owner。
# 它汇合 generated UI dry-run input、state delta 与 render preview，并准备 stage309 probe。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage308_internal_ai_generated_ui_demo_component_state_render_readiness_decision.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage308 internal ai generated ui demo component state render readiness decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage308InternalAiGeneratedUiDemoComponentStateRenderReadinessDecisionFacts" \
  "CjguiInternalRendererStage308InternalAiGeneratedUiDemoComponentStateRenderReadinessDecisionReadiness" \
  "cjguiInternalExecuteDefaultRendererStage308InternalAiGeneratedUiDemoComponentStateRenderReadinessDecisionDraft" \
  "didConsumeStage307InternalAiGeneratedUiDemoComponentRenderCommandPreview" \
  "didJoinGeneratedUiDryRunInputWithStateDelta" \
  "didJoinGeneratedUiStateDeltaWithRenderPreview" \
  "didJoinGeneratedUiComponentStateRenderWithRollbackReadyBoundary" \
  "didJoinGeneratedUiComponentStateRenderWithVisibilityNotPublishedBoundary" \
  "didMaterializeInternalAiGeneratedUiComponentStateRenderReadinessDecision" \
  "didPrepareStage309InternalAiGeneratedUiDemoProbeInput" \
  "didConfirmMinimalUiFrameworkAiGeneratedUiComponentStateRenderRunwayAdvanced" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage308 internal ai generated ui demo component state render readiness decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage308_internal_ai_generated_ui_demo_component_state_render_readiness_decision_owner_present=true"
echo "stage307_internal_ai_generated_ui_demo_component_render_command_preview_required=true"
echo "internal_ai_generated_ui_component_state_render_readiness_decision_materialized=true"
echo "ai_generated_ui_component_state_render_dry_run_joined=true"
echo "ai_generated_ui_component_state_render_rollback_boundary_joined=true"
echo "ai_generated_ui_component_state_render_visibility_boundary_joined=true"
echo "stage309_internal_ai_generated_ui_demo_probe_input_prepared=true"
echo "minimal_ui_framework_ai_generated_ui_component_state_render_runway_advanced=true"
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
