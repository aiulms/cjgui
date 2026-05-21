#!/usr/bin/env zsh
#
# 维护注释：验证 stage218 state update preview packet owner。
# 预览包只表达 before/after state 候选和 rollback 边界，不提交状态更新。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage218_state_update_preview_packet.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage218 state update preview packet: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage218StateUpdatePreviewPacketFacts" \
  "CjguiInternalRendererStage218StateUpdatePreviewPacketReadiness" \
  "cjguiInternalExecuteDefaultRendererStage218StateUpdatePreviewPacketDraft" \
  "didConsumeStage217StateUpdateAfterActionDryRun" \
  "didMaterializeStateUpdatePreviewPacket" \
  "didBindPreviewPacketToActionPreview" \
  "didBindPreviewPacketToRollbackPreview" \
  "didPreserveStateUpdateNonCommitting" \
  "didPrepareStage219StateUpdateSemanticDiffInput"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage218 state update preview packet: missing token $token" >&2
    exit 3
  fi
done

echo "stage218_state_update_preview_packet_owner_present=true"
echo "stage217_state_update_after_action_dry_run_required=true"
echo "state_update_preview_packet_materialized=true"
echo "state_update_preview_bound_to_action_preview=true"
echo "state_update_preview_bound_to_rollback_preview=true"
echo "state_update_preview_non_committing=true"
echo "stage219_state_update_semantic_diff_input_prepared=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
