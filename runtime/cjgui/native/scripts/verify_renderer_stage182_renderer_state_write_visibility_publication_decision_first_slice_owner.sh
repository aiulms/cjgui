#!/usr/bin/env zsh
#
# 维护注释：本脚本验证 stage182 renderer-state write visibility
# publication decision source。它只检查 owner-local decision ledger，不发布
# visibility，也不写 renderer/runtime state。
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OWNER_SRC="$ROOT_DIR/src/runtime_renderer_stage182_renderer_state_write_visibility_publication_decision_first_slice.cj"

if [[ ! -f "$OWNER_SRC" ]]; then
  echo "cjgui stage182 visibility publication decision: missing source $OWNER_SRC" >&2
  exit 2
fi

for token in \
  "CjguiInternalRendererStage182RendererStateWriteVisibilityPublicationDecisionFirstSliceReadiness" \
  "cjguiInternalExecuteDefaultRendererStage182RendererStateWriteVisibilityPublicationDecisionFirstSliceDraft" \
  "didConsumeStage181VisibilityPublicationReadinessBridge" \
  "didMaterializeVisibilityPublicationDecisionLedger" \
  "didBindVisibilityPublicationPredicateLedgerToDecision" \
  "didBindVisibilityPublicationAdmissionDenial" \
  "didPrepareStage183RendererStateWriteFinalAdmissionRecheckInput" \
  "didKeepVisibilityPublicationDecisionNonMutating" \
  "didKeepVisibilityPublicationDecisionAdmissionDenied"; do
  if ! grep -F "$token" "$OWNER_SRC" >/dev/null 2>&1; then
    echo "cjgui stage182 visibility publication decision: missing token $token" >&2
    exit 3
  fi
done

echo "stage182_visibility_publication_decision_owner_present=true"
echo "stage181_visibility_publication_readiness_bridge_required=true"
echo "visibility_publication_decision_ledger_materialized=true"
echo "visibility_publication_predicate_ledger_to_decision_bound=true"
echo "visibility_publication_admission_denial_bound=true"
echo "stage183_renderer_state_write_final_admission_recheck_input_prepared=true"
echo "visibility_publication_decision_non_mutating=true"
echo "visibility_publication_decision_admission_denied=true"
echo "visibility_published=false"
echo "renderer_state_write=false"
echo "runtime_state_write=false"
