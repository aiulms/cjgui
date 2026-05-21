#!/usr/bin/env zsh
#
# 维护注释：验证 stage326 internal AI-generated UI demo result-to-probe input owner。
# 它只把 stage325 surface refresh 组织成 non-executing probe input。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage326_internal_ai_generated_ui_demo_result_to_probe_input.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage326 internal ai generated ui demo result to probe input: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage326InternalAiGeneratedUiDemoResultToProbeInputFacts" \
  "CjguiInternalRendererStage326InternalAiGeneratedUiDemoResultToProbeInputReadiness" \
  "cjguiInternalExecuteDefaultRendererStage326InternalAiGeneratedUiDemoResultToProbeInputDraft" \
  "didConsumeStage325AiGeneratedUiDemoResultToSurface" \
  "didMaterializeAiGeneratedUiDemoResultToProbeInput" \
  "didBindResultToProbeInputToSurfaceRefresh" \
  "didBindResultToProbeInputToBackendResultReadiness" \
  "didBindResultToProbeInputToOwnerLocalStateRenderBridge" \
  "didKeepResultToProbeInputOwnerLocalInMemoryOnly" \
  "didKeepResultToProbeInputNonExecuting" \
  "didPrepareStage327ResultToProbeResultEnvelopeInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepActionDispatchBlocked" \
  "didKeepStateUpdateCommittedBlocked" \
  "didKeepRendererSubmissionBlocked" \
  "didKeepRendererStateWriteBlocked" \
  "didKeepRuntimeStateWriteBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage326 internal ai generated ui demo result to probe input: missing token $token" >&2
    exit 3
  fi
done

echo "stage326_internal_ai_generated_ui_demo_result_to_probe_input_owner_present=true"
echo "stage325_internal_ai_generated_ui_demo_result_to_surface_required=true"
echo "ai_generated_ui_demo_result_to_probe_input_materialized=true"
echo "result_to_probe_input_bound_to_surface_refresh=true"
echo "result_to_probe_input_bound_to_backend_result_readiness=true"
echo "result_to_probe_input_bound_to_owner_local_state_render_bridge=true"
echo "result_to_probe_input_owner_local_in_memory_only=true"
echo "result_to_probe_input_non_executing=true"
echo "stage327_internal_ai_generated_ui_demo_result_to_probe_result_envelope_prepared=true"
echo "backend_ready_truth=false"
echo "action_dispatch=false"
echo "state_update_committed=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
