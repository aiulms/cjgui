#!/usr/bin/env zsh
set -euo pipefail

# Consumer RED: both normal applications must declare at least one command
# against an existing scoped owner action. This is intentionally source-level
# so it can run before either example is built.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RULE="$ROOT/examples/rule_set_window_app/src/main.cj"
DOC="$ROOT/examples/shared_document_window_app/src/main.cj"

rg -q 'CjguiComposableUiNodeReference\.scoped\(presentationScope, "open-menu"\)' "$RULE"
rg -q -U 'CjguiComposableUiCommand\(\s*"rule-set\.open-presentation-menu"' "$RULE"
rg -q 'CjguiComposableUiNodeReference\.scoped\(actionScope\.child\("item"\), "save"\)' "$DOC"
rg -q -U 'CjguiComposableUiCommand\(\s*"shared-document\.save"' "$DOC"

print "CJGUI_COMMAND_MENU_CONSUMERS scoped_declarations=true"
