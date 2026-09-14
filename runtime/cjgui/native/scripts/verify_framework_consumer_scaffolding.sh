#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TEMPLATE_DIR="$RUNTIME_DIR/templates/macos_application"

test -x "$RUNTIME_DIR/scripts/create_macos_application.sh"
test -x "$RUNTIME_DIR/scripts/export_framework_preview.sh"
test -f "$TEMPLATE_DIR/ui_only/cjpm.toml"
test -f "$TEMPLATE_DIR/ui_only/src/main.cj"
test -f "$TEMPLATE_DIR/collaboration/cjpm.toml"
test -f "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -q 'CjguiMacosApplicationHost' "$TEMPLATE_DIR/ui_only/src/main.cj" "$TEMPLATE_DIR/collaboration/src/main.cj"
! rg -q 'CjguiSharedOperationExternalConnection|DESCRIPTOR_PATH' "$TEMPLATE_DIR/ui_only"
rg -q 'CjguiSharedOperationExternalConnection' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -q 'CjguiComposableUiComponentRegistry' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -q 'cjgui_shared_operation_core' "$TEMPLATE_DIR/collaboration/cjpm.toml"
# The collaboration starter's editable value and submission flag must be one
# shared record, not controller-local draft/count state next to an unrelated
# socket operation.  An empty text projection is allowed; only the submit
# boundary performs the required-content check.
! rg -q 'humanTaskCount|private var draft|EDIT_DRAFT' "$TEMPLATE_DIR/collaboration/src/main.cj"
! rg -q 'event\.text\.trim' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -F -q 'setTitleFromHuman(TASK_RESOURCE_ID, event.text)' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -F -q 'setMarkedFromHuman(TASK_RESOURCE_ID, true)' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -F -q 'fieldId: "title", operationActionName: "SET_TITLE"' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -F -q 'CjguiSharedOperationExternalActionScope("SET_TITLE"' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -F -q 'CjguiSharedOperationExternalActionScope("SET_MARKED"' "$TEMPLATE_DIR/collaboration/src/main.cj"
rg -q 'preview-manifest' "$RUNTIME_DIR/scripts/export_framework_preview.sh"
rg -q 'create_macos_application.sh' "$RUNTIME_DIR/scripts/export_framework_preview.sh"
rg -q 'shared_operation_core/client.py' "$RUNTIME_DIR/scripts/export_framework_preview.sh"
rg -q 'PREVIEW_CJGUI_SOURCES' "$RUNTIME_DIR/scripts/export_framework_preview.sh"
rg -q 'PREVIEW_CORE_SOURCES' "$RUNTIME_DIR/scripts/export_framework_preview.sh"

echo 'cjgui_framework_consumer_scaffolding=ok'
