#!/usr/bin/env zsh
set -euo pipefail

CJGUI_MACOS_APP_BUNDLE_NAME='CJGUIUiOnlyStarter'
CJGUI_MACOS_APP_EXECUTABLE_NAME='CJGUIUiOnlyStarter'
CJGUI_MACOS_APP_IDENTIFIER='org.example.cjgui.ui-only-starter'
CJGUI_MACOS_APP_DISPLAY_NAME='CJGUI UI-only Starter'
CJGUI_MACOS_APP_RESOURCES=(
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon.png"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch.png"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch.jpg"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch-v2.jpg"
  "$CJGUI_RUNTIME_DIR/resources/preview-corrupt.jpg"
)
