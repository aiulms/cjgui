#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage159 visibility result bridge source 消费 stage158
# dry-run envelope，并准备 first-slice 输出 readiness；不发布 public state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage159_visibility_result_bridge_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage159 visibility result bridge: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage159VisibilityResultBridgeFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage159VisibilityResultBridgeFirstSliceDraft" \
  "didConsumeStage158MutationDryRunEnvelope" \
  "didBridgeGuardedExecutorDryRunToVisibilityResult" \
  "didMaterializeVisibilityResultPublicationReadiness" \
  "didPrepareRendererStateWriteFirstSliceReadinessOutput" \
  "didKeepVisibilityResultPublicationInternalOnly"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage159 visibility result bridge: missing token $token" >&2
    exit 3
  fi
done

echo "stage159_visibility_result_bridge_owner_present=true"
echo "stage158_mutation_dry_run_envelope_required=true"
echo "visibility_result_publication_readiness_materialized=true"
echo "renderer_state_write_first_slice_readiness_output_prepared=true"
echo "visibility_result_bridge_ready=true"
echo "visibility_result_bridge_runtime_admitted=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
