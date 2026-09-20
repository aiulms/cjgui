#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
SOURCE="$RUNTIME_DIR/probe/framework_preview_vector_consumer.cj"

# The public preview verifier may prove its external projection, but it must
# not call the sibling chart command and label unchanged A state as a human
# action. A separately invocable normal mode keeps the same public owners
# alive for desktop input evidence.
rg -q 'private func runInteractiveVectorConsumer\(\): Int64' "$SOURCE"
rg -q 'CJGUI_VECTOR_INTERACTIVE_READY' "$SOURCE"
rg -q 'args\[0\] == "--run-vector"' "$SOURCE"
! rg -q 'let humanAction = chartWindow\.invokeCommand\("chart\.input"\)' "$SOURCE"
rg -q 'human_action=false' "$SOURCE"
rg -q 'human_readback=false' "$SOURCE"

print -- 'CJGUI_VECTOR_PUBLIC_CONSUMER_CONTRACT passed=true'
