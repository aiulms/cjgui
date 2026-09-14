#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
NOTIFICATION_DIR="$RUNTIME_DIR/examples/notification_threshold_window_app"
RUNNER="$RUNTIME_DIR/scripts/run_macos_application.sh"

# A shipped app must use the same public Host/runner path as a newly created
# app.  This is intentionally structural: it prevents a future app-specific
# FFI launcher, loop, or fixed SDK from silently becoming a second entry path.
test -f "$NOTIFICATION_DIR/cjgui_macos_app.sh"
rg -q 'run_macos_application\.sh' "$NOTIFICATION_DIR/run.sh"
rg -q 'CJGUI_MACOS_APP_BUNDLE_NAME' "$NOTIFICATION_DIR/cjgui_macos_app.sh"
rg -q 'CJGUI_MACOS_APP_RESOURCES' "$NOTIFICATION_DIR/cjgui_macos_app.sh"
rg -q 'cjgui_macos_application_launcher = \{ path = "\./\.cjgui/native/lib" \}' "$NOTIFICATION_DIR/cjpm.toml"
rg -q 'cjgui_internal_renderer = \{ path = "\./\.cjgui/native/lib" \}' "$NOTIFICATION_DIR/cjpm.toml"

rg -q 'CjguiMacosApplicationHost' "$NOTIFICATION_DIR/src/main.cj"
rg -q 'attachExternalConnection' "$NOTIFICATION_DIR/src/main.cj"
rg -q 'pumpOneTurn' "$NOTIFICATION_DIR/src/main.cj"
! rg -q 'foreign func cjgui_shared_operation_window_app_finish|connection\.pump|window\.pump|sleep\(Duration' "$NOTIFICATION_DIR/src/main.cj"
! rg -q 'cangjie-toolchains|MacOSX15\.4\.sdk|clang -fobjc' "$NOTIFICATION_DIR/run.sh"

# A source preview has no access to a repository author's toolchain path.  A
# selected CANGJIE_HOME is the default, and an override is explicit and
# diagnosable; the 1.1.3 policy remains enforced by the runner.
! rg -q 'DEFAULT_CJGUI_CANGJIE_HOME=.*/Users/' "$RUNNER"
rg -q 'CJGUI_CANGJIE_HOME:-\$\{CANGJIE_HOME:-\}' "$RUNNER"
rg -q 'no selected Cangjie toolchain' "$RUNNER"
rg -q 'default toolchain must be Cangjie 1\.1\.3' "$RUNNER"
rg -q 'framework_native_archive=rebuilt' "$RUNNER"
rg -q 'FRAMEWORK_RENDERER_ARCHIVE' "$RUNNER"
rg -q 'CJGUI_NATIVE_SOURCE_DIR:-\$RUNTIME_DIR/native' "$RUNNER"
rg -q 'source_origin runtime=' "$RUNNER"
rg -q 'resource_origin=' "$RUNNER"

echo 'cjgui_framework_consumption_entrypoints=ok'
