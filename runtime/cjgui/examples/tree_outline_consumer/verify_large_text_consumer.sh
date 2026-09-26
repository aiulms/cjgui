#!/usr/bin/env zsh
set -euo pipefail

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="${CJGUI_TREE_OUTLINE_LARGE_TEXT_LOG:-/private/tmp/cjgui-tree-outline-large-text.log}"

: "${CJGUI_CANGJIE_HOME:=/Users/jiangxuanyang/cangjie-toolchains/cangjie-1.1.3}"
export CJGUI_CANGJIE_HOME
export CJGUI_TREE_OUTLINE_TEXT_FIXTURE=large-text
export CJGUI_TREE_OUTLINE_ACCEPTANCE_ONESHOT=1

zsh "$APP_DIR/run.sh" > "$LOG" 2>&1

grep -q '^TREE_OUTLINE_CONSUMER_READY .*fixture=large-text ' "$LOG" \
  || { echo "large-text consumer: normal application host did not select the fixture (log=$LOG)" >&2; exit 1; }
grep -Eq '^TREE_OUTLINE_CONSUMER_LARGE_TEXT node_id=[1-9][0-9]* identity=[^ ]+ value_size=[1-9][0-9]{3,} width=[1-9][0-9]* height=[1-9][0-9]* rename=true refreshed=true identity_same=true value_changed=true after_size=[1-9][0-9]{3,}$' "$LOG" \
  || { echo "large-text consumer: accepted identity/size or public interaction evidence missing (log=$LOG)" >&2; exit 1; }

echo "PASSED tree outline large text consumer host output=$LOG"
