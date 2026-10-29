#!/usr/bin/env zsh
set -euo pipefail
CJGUI_MACOS_APP_BUNDLE_NAME='CJGUIMixedFormStarter'
CJGUI_MACOS_APP_EXECUTABLE_NAME='CJGUIMixedFormStarter'
CJGUI_MACOS_APP_IDENTIFIER='org.example.cjgui.mixed-form-starter'
CJGUI_MACOS_APP_DISPLAY_NAME='打印预设 · 混合表单'
export CJGUI_PRINT_PRESET_DESCRIPTION="$APP_DIR/assets/styled-description.tsv"
CJGUI_MACOS_APP_RESOURCES=("$APP_DIR/assets/styled-description.tsv"
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon.png"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch.png"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch.jpg"
  "$CJGUI_RUNTIME_DIR/resources/preview-swatch-v2.jpg"
  "$CJGUI_RUNTIME_DIR/resources/preview-corrupt.jpg"
  "$CJGUI_RUNTIME_DIR/resources/fonts/Lilex-Regular.ttf" "$CJGUI_RUNTIME_DIR/resources/fonts/OFL.txt")
