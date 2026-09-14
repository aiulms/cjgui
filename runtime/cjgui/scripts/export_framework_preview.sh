#!/usr/bin/env zsh
set -euo pipefail

if (( $# != 1 )); then
  print -u2 'usage: export_framework_preview.sh DESTINATION'
  exit 2
fi

DESTINATION="$1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RUNTIME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
if [[ -e "$DESTINATION" ]]; then
  print -u2 -- "cjgui preview: destination already exists: $DESTINATION"
  exit 2
fi
DESTINATION_PARENT="$(cd "$(dirname "$DESTINATION")" && pwd)"
DESTINATION="$DESTINATION_PARENT/$(basename "$DESTINATION")"
STAGING_DIR="$(mktemp -d "$DESTINATION_PARENT/.$(basename "$DESTINATION").cjgui-preview.XXXXXX")"
cleanup() { rm -rf "$STAGING_DIR"; }
trap cleanup EXIT HUP INT TERM

FRAMEWORK_DIR="$STAGING_DIR/framework/cjgui"
mkdir -p "$FRAMEWORK_DIR"
cp "$RUNTIME_DIR/cjpm.toml" "$FRAMEWORK_DIR/cjpm.toml"
mkdir -p "$FRAMEWORK_DIR/src" "$FRAMEWORK_DIR/shared_operation_core/src" "$FRAMEWORK_DIR/native" \
  "$FRAMEWORK_DIR/resources" "$FRAMEWORK_DIR/scripts" "$FRAMEWORK_DIR/templates"

# Keep only the implementation that backs today's public composable-window
# surface. Historical internal probes and unrelated runtime sketches are not
# a preview SDK dependency. Add a file here only when its exported type is
# needed by one of these public entry points.
typeset -a PREVIEW_CJGUI_SOURCES
PREVIEW_CJGUI_SOURCES=(
  composable_ui.cj
  composable_ui_component_instance.cj
  composable_ui_window.cj
  macos_application_host.cj
  runtime_renderer_session.cj
)
for source_name in "${PREVIEW_CJGUI_SOURCES[@]}"; do
  cp "$RUNTIME_DIR/src/$source_name" "$FRAMEWORK_DIR/src/$source_name"
done
cp "$RUNTIME_DIR/shared_operation_core/cjpm.toml" "$FRAMEWORK_DIR/shared_operation_core/cjpm.toml"
cp "$RUNTIME_DIR/shared_operation_core/client.py" "$FRAMEWORK_DIR/shared_operation_core/client.py"
typeset -a PREVIEW_CORE_SOURCES
PREVIEW_CORE_SOURCES=(
  shared_editing_form_contract.cj
  shared_operation_contract.cj
  shared_operation_list.cj
  shared_operation_transport.cj
  shared_text_document.cj
  shared_text_document_workspace.cj
  shared_text_document_file.cj
)
for source_name in "${PREVIEW_CORE_SOURCES[@]}"; do
  cp "$RUNTIME_DIR/shared_operation_core/src/$source_name" "$FRAMEWORK_DIR/shared_operation_core/src/$source_name"
done
for source in cjgui_internal_renderer.m cjgui_internal_renderer.h cjgui_native_bridge.m cjgui_native_bridge.h cjgui_macos_application_launcher.m; do
  cp "$RUNTIME_DIR/native/$source" "$FRAMEWORK_DIR/native/$source"
done
cp "$RUNTIME_DIR/resources/composable-beacon.png" "$RUNTIME_DIR/resources/composable-beacon-coral.png" "$FRAMEWORK_DIR/resources/"
cp "$RUNTIME_DIR/scripts/run_macos_application.sh" "$RUNTIME_DIR/scripts/create_macos_application.sh" "$FRAMEWORK_DIR/scripts/"
cp -R "$RUNTIME_DIR/templates/macos_application" "$FRAMEWORK_DIR/templates/"
cp "$RUNTIME_DIR/preview/FRAMEWORK_PREVIEW_MANIFEST.md" "$STAGING_DIR/preview-manifest.md"
chmod +x "$FRAMEWORK_DIR/scripts/run_macos_application.sh" "$FRAMEWORK_DIR/scripts/create_macos_application.sh" \
  "$FRAMEWORK_DIR/templates/macos_application"/*/*.sh
mv "$STAGING_DIR" "$DESTINATION"
trap - EXIT HUP INT TERM
print -r -- "cjgui preview: exported=$DESTINATION"
