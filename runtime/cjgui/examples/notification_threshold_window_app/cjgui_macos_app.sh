#!/usr/bin/env zsh
set -euo pipefail

CJGUI_MACOS_APP_BUNDLE_NAME='CJGUINotificationThreshold'
CJGUI_MACOS_APP_EXECUTABLE_NAME='CJGUINotificationThreshold'
CJGUI_MACOS_APP_IDENTIFIER='org.cangjie.cjgui.notification-threshold.example'
CJGUI_MACOS_APP_DISPLAY_NAME='通知阈值'
CJGUI_MACOS_APP_RESOURCES=(
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon.png"
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon-coral.png"
)
