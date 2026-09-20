#!/usr/bin/env zsh

# The existing normal adaptive-layout app must own a public vector component
# whose activation uses its pre-existing TOGGLE_RESOURCE action.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE="$RUNTIME_DIR/examples/adaptive_layout_public_consumer/src/main.cj"

rg -q '"adaptive-vector-beacon"' "$SOURCE"
rg -q 'cjguiComposableVectorGraphic' "$SOURCE"
rg -q 'interactive: true, actionName: "TOGGLE_RESOURCE"' "$SOURCE"
rg -q 'ADAPTIVE_LAYOUT_VECTOR_DECLARATION' "$SOURCE"
print -- 'CJGUI_ADAPTIVE_LAYOUT_VECTOR_CONSUMER_CONTRACT passed=true'
