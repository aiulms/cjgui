#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
NATIVE_SOURCE="$RUNTIME_DIR/native/cjgui_internal_renderer.m"

# A vector scene may opt into a multisample attachment, but ordinary
# text/form/image scenes must keep the prior single-sample drawable path.
# Prepared local triangles likewise belong to an accepted node; the encoder
# may apply current layout/paint/clip but must not re-tessellate geometry on
# every submitted frame.
require_symbol() {
  local symbol="$1"
  if ! rg -q "$symbol" "$NATIVE_SOURCE"; then
    print -u2 -- "vector render-path contract: missing $symbol"
    exit 1
  fi
}

require_symbol 'static BOOL CjguiComposableSceneNeedsMultisampling'
require_symbol 'if \(needsMultisampling\)'
require_symbol 'CjguiComposablePreparedVectorTrianglesForNode'
require_symbol 'vectorPreparedTriangles'

print -- 'CJGUI_VECTOR_RENDER_PATH_CONTRACT passed=true'
