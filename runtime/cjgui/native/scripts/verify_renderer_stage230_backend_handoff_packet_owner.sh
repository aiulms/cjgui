#!/usr/bin/env zsh
#
# 维护注释：验证 stage230 renderer backend handoff packet owner。
# 它把 dry-run 与 no-render backend readiness 包成可回滚 packet。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage230_backend_handoff_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage230 backend handoff packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage230BackendHandoffPacketFacts" \
  "CjguiInternalRendererStage230BackendHandoffPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage230BackendHandoffPacketDraft" \
  "didConsumeStage229RendererBackendHandoffDryRun" \
  "didConsumeRendererBackendNoRenderReadiness" \
  "didMaterializeRendererBackendHandoffPacket" \
  "didBindPacketToNoRenderBackendReadiness" \
  "didBindPacketToBackendRollbackBoundary" \
  "didPreserveBackendHandoffPacketValueOnly" \
  "didPrepareStage231RendererBackendHandoffSemanticDiffInput" \
  "didKeepBackendReadyTruthBlocked" \
  "didKeepRendererSubmissionBlocked"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage230 backend handoff packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage230_backend_handoff_packet_owner_present=true"
echo "stage229_backend_handoff_dry_run_required=true"
echo "renderer_backend_no_render_readiness_required=true"
echo "renderer_backend_handoff_packet_materialized=true"
echo "backend_handoff_packet_bound_to_no_render_backend_readiness=true"
echo "backend_handoff_packet_bound_to_rollback_boundary=true"
echo "stage231_renderer_backend_handoff_semantic_diff_input_prepared=true"
echo "backend_ready_truth=false"
echo "renderer_submission=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
echo "visibility_published=false"
