#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage147 renderer-state write admission owner 只声明
# production truth 后续 write admission 合同，不构造 mutation request。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage147_renderer_state_write_admission_after_production_truth_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage147 write admission owner: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage147RendererStateWriteAdmissionAfterProductionTruthFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage147RendererStateWriteAdmissionAfterProductionTruthFirstSliceDraft" \
  "didRequireProductionRenderTruthBeforeWriteAdmission" \
  "didRequireBackendReadyTruthBeforeWriteAdmission" \
  "didRequireProductionWriteAdmissionToken" \
  "didKeepWriteAdmissionNonMutating"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage147 write admission owner: missing token $token" >&2
    exit 3
  fi
done

echo "stage147_renderer_state_write_admission_after_production_truth_owner_present=true"
echo "stage146_production_truth_packet_required=true"
echo "production_render_truth_before_write_admission_required=true"
echo "backend_ready_truth_before_write_admission_required=true"
echo "production_write_admission_token_required=true"
echo "state_mutation_request_envelope_required=true"
echo "renderer_state_write_admission_non_mutating=true"
echo "state_mutation_request_blocked=true"
echo "visibility_publication_blocked=true"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
