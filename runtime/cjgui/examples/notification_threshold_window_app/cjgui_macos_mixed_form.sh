#!/usr/bin/env zsh
set -euo pipefail

CJGUI_MACOS_APP_BUNDLE_NAME='CJGUINotificationMixed'
CJGUI_MACOS_APP_EXECUTABLE_NAME='CJGUINotificationMixed'
CJGUI_MACOS_APP_IDENTIFIER='org.cangjie.cjgui.notification-mixed.example'
CJGUI_MACOS_APP_DISPLAY_NAME='通知配置 · 手写与生成'
CJGUI_MACOS_APP_RESOURCES=(
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon.png"
  "$CJGUI_RUNTIME_DIR/resources/composable-beacon-coral.png"
)
