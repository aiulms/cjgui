#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

test -f "$RUNTIME_DIR/native/cjgui_macos_application_launcher.m"
test -f "$RUNTIME_DIR/scripts/run_macos_application.sh"

rg -q 'cjgui_macos_application_launcher' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'CJGUI_MACOS_APP_BUNDLE_NAME' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'format=2' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'hash_file' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'CJGUI_NATIVE_SOURCE_DIR' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'macos_application_build.lock' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'bundle-staging' "$RUNTIME_DIR/scripts/run_macos_application.sh"
rg -q 'open -W .*--args' "$RUNTIME_DIR/scripts/run_macos_application.sh"

! rg -q 'CjguiMacosApplicationRunner|CjguiMacosApplicationTurnSource' \
  "$RUNTIME_DIR/src/macos_application_host.cj" "$RUNTIME_DIR/src/composable_ui_platform_state.cj" "$RUNTIME_DIR/src/macos_application_host_test.cj"
rg -q 'requestCloseFromApplication' "$RUNTIME_DIR/src/composable_ui_window.cj"
rg -q 'public func requestClose' "$RUNTIME_DIR/src/macos_application_host.cj"
! sed -n '/static CjguiInternalRendererStatus CjguiCommitComposableSceneOnMain/,/return CJGUI_INTERNAL_RENDERER_OK/p' \
  "$RUNTIME_DIR/native/cjgui_internal_renderer.m" | rg -q 'setTitle'

for app_dir in "$RUNTIME_DIR/examples/rule_set_window_app" "$RUNTIME_DIR/examples/shared_document_window_app"; do
  test -f "$app_dir/cjgui_macos_app.sh"
  rg -q 'run_macos_application.sh' "$app_dir/run.sh"
  ! rg -q 'shared_operation_window_app/native/macos_launcher|cjgui_shared_operation_window_app_finish' "$app_dir/run.sh" "$app_dir/src/main.cj"
done

rg -q 'verify-host-close-decisions' "$RUNTIME_DIR/examples/rule_set_window_app/src/main.cj"
rg -q 'verify-connection-start-failure' "$RUNTIME_DIR/examples/shared_document_window_app/src/main.cj"

echo 'cjgui_macos_application_host_runner=ok'
